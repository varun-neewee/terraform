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

    # set google cloud project
    gcloud config set project "${var.project_id}"
    if [ $? -ne 0 ]; then
      error_message=$(gcloud config set project ${var.project_id} 2>&1)
      send_email "GCloud config set Failed" "Failed to set gcloud config Error: $error_message"
      exit 1
    fi

    # Connect to the Google Kubernetes Engine cluster
    gcloud container clusters get-credentials "${var.cluster_name}" --region "${var.region}" --project "${var.project_id}"
    if [ $? -ne 0 ]; then
      error_message=$(gcloud container clusters get-credentials "${var.cluster_name}" --region "${var.region}" --project "${var.project_id}" 2>&1)
      send_email "GCloud container cluster Failed" "Failed at gcloud container clusters Error: $error_message"
      exit 1
    fi

    # Loop through each namespace
    for namespace in ${join(" ", var.namespaces)}; do
      echo "Processing \$namespace..."

      # upgrade Helm chart
      kubectl delete namespace "$namespace"
     if [ $? -ne 0 ]; then
        error_message=$(kubectl delete namespace "$namespace" 2>&1)
        send_email "Command Execution Failed for $namespace" "Command execution failed for $namespace during deleteing namespace step. Error: $error_message"
        continue
      fi


      # Send success email
      send_email "$namespace successfully deleted" "$namespace is deleted"

      # Sleep for 10 seconds before proceeding to the next namespace
      sleep 10
    done

    echo "Script completed."
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}
