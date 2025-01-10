resource "null_resource" "run_commands" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<EOT
    #!/bin/bash

    # Function to send email
    send_email() {
      local subject="$1"
      local body="$2"
      local recipient="${var.email_recipient}"
      local sender="${var.email_sender}"

      echo -e "To: $recipient\nFrom: $sender\nSubject: $subject\n\n$body" | ssmtp "$recipient"
    }

    # Authenticate with Google Cloud
    gcloud auth activate-service-account --key-file="${var.key_file}"
    if [ $? -ne 0 ]; then
      error_message=$(gcloud auth activate-service-account --key-file="${var.key_file}" 2>&1)
      send_email "GCloud Authentication Failed" "GCloud authentication failed. Error: $error_message"
      exit 1
    fi

    # Set Google Cloud project configuration
    gcloud config set project "${var.project_id}" --quiet
    if [ $? -ne 0 ]; then
      error_message=$(gcloud config set project "${var.project_id}" --quiet 2>&1)
      send_email "GCloud Config Set Project Failed" "Failed to set GCloud project configuration. Error: $error_message"
      exit 1
    fi

    # Connect to the Google Kubernetes Engine cluster
    gcloud container clusters get-credentials "${var.cluster_name}" --region "${var.region}" --project "${var.project_id}"
    if [ $? -ne 0 ]; then
      error_message=$(gcloud container clusters get-credentials "${var.cluster_name}" --region "${var.region}" --project "${var.project_id}" 2>&1)
      send_email "GCloud Get Credentials Failed" "Failed to connect to GKE cluster. Error: $error_message"
      exit 1
    fi

    # Loop through each namespace
    for namespace in ${join(" ", var.namespaces)}; do
      echo "Processing \$namespace..."

      # Create namespace
      kubectl create namespace "$namespace"
      if [ $? -ne 0 ]; then
        error_message=$(kubectl create namespace "$namespace" 2>&1)
        send_email "Command Execution Failed for $namespace" "Command execution failed for $namespace during kubectl create namespace step. Error: $error_message"
        continue
      fi

      # Set context to the new namespace
      kubectl config set-context --current --namespace="$namespace"
      if [ $? -ne 0 ]; then
        error_message=$(kubectl config set-context --current --namespace="$namespace" 2>&1)
        send_email "Command Execution Failed for $namespace" "Command execution failed for $namespace during kubectl config set-context step. Error: $error_message"
        continue
      fi

      # Modify and replace PersistentVolume
      kubectl get pv bps-non-production-"$namespace"-pv -o json | jq 'del(.spec.claimRef)' | kubectl replace -f -
      if [ $? -ne 0 ]; then
        error_message=$(kubectl get pv bps-non-production-"$namespace"-pv -o json | jq 'del(.spec.claimRef)' | kubectl replace -f - 2>&1)
        send_email "Command Execution Failed for $namespace" "Command execution failed for $namespace during kubectl replace PersistentVolume step. Error: $error_message"
        continue
      fi

      # Create service account
      kubectl create sa ksa-"$namespace"
      if [ $? -ne 0 ]; then
        error_message=$(kubectl create sa ksa-"$namespace" 2>&1)
        send_email "Command Execution Failed for $namespace" "Command execution failed for $namespace during kubectl create sa step. Error: $error_message"
        continue
      fi

      # Add IAM policy binding
      gcloud iam service-accounts add-iam-policy-binding gsa-"$namespace"@"${var.project_id}".iam.gserviceaccount.com --role roles/iam.workloadIdentityUser --member "serviceAccount:${var.project_id}.svc.id.goog[$namespace/ksa-$namespace]"
      if [ $? -ne 0 ]; then
        error_message=$(gcloud iam service-accounts add-iam-policy-binding gsa-"$namespace"@"${var.project_id}".iam.gserviceaccount.com --role roles/iam.workloadIdentityUser --member "serviceAccount:${var.project_id}.svc.id.goog[$namespace/ksa-\$namespace]" 2>&1)
        send_email "Command Execution Failed for \$namespace" "Command execution failed for \$namespace during gcloud iam policy binding step. Error: $error_message"
        continue
      fi

      # Annotate service account
      kubectl annotate serviceaccount ksa-"$namespace" --namespace "$namespace" iam.gke.io/gcp-service-account=gsa-"$namespace"@"${var.project_id}".iam.gserviceaccount.com
      if [ $? -ne 0 ]; then
        error_message=$(kubectl annotate serviceaccount ksa-"\$namespace" --namespace "\$namespace" iam.gke.io/gcp-service-account=gsa-"$namespace"@"${var.project_id}".iam.gserviceaccount.com 2>&1)
        send_email "Command Execution Failed for $namespace" "Command execution failed for $namespace during kubectl annotate sa step. Error: $error_message"
        continue
      fi

      # Install Helm chart
      helm install "$namespace" "${var.helm_path}""$namespace" --values "${var.helm_path}""$namespace"/values.yaml --values "${var.helm_path}""$namespace"/images.yaml -n "$namespace"
      if [ $? -ne 0 ]; then
        error_message=$(helm install "$namespace" "${var.helm_path}""$namespace" --values "${var.helm_path}""$namespace"/values.yaml -n "$namespace" 2>&1)
        send_email "Command Execution Failed for $namespace" "Command execution failed for $namespace during helm install step. Error: $error_message"
        continue
      fi

      # Send success email
      send_email "$namespace  successfully deployed" "$namespace is up and running"

      # Sleep for 10 seconds before proceeding to the next namespace
      sleep 10
    done

    echo "Script completed."
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}
