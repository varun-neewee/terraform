locals {
  selected_indices = split(",", var.namespaces)
  selected_namespaces = [for idx in local.selected_indices : var.available_namespaces[tonumber(idx)]]
}

# Output the selected namespaces for verification
output "selected_namespaces" {
  value = local.selected_namespaces
}

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

    # git pull
    cd "${var.helm_path}" && git pull https://github.com/neeweebodhee/bxs-helm-chart.git master
    if [ $? -ne 0 ]; then
      error_message=$(git pull 2>&1)
      send_email "git pull failed" "git pull failed. Error: $error_message"
      exit 1
    fi

    gcloud auth activate-service-account --key-file="${var.key_file}"
    if [ $? -ne 0 ]; then
      error_message=$(gcloud auth activate-service-account --key-file="${var.key_file}" 2>&1)
      send_email "gcloud auth failed" "Failed to activate gcloud auth Error: $error_message"
      exit 1
    fi

    # Set Google Cloud project configuration
    gcloud config set project "${var.project_id}"
    if [ $? -ne 0 ]; then
      error_message=$(gcloud config set project "${var.project_id}" 2>&1)
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
    for namespace in ${join(" ", local.selected_namespaces)}; do
      echo "Processing \$namespace..."

      # upgrade Helm chart
      helm upgrade "$namespace" "${var.helm_path}""$namespace" --values "${var.helm_path}""$namespace"/values.yaml --values "${var.helm_path}""$namespace"/images.yaml -n "$namespace"
      if [ $? -ne 0 ]; then
        error_message=$(helm upgrade "$namespace" "${var.helm_path}""$namespace" --values "${var.helm_path}""$namespace"/values.yaml -n "$namespace" 2>&1)
        send_email "Command Execution Failed for $namespace" "Command execution failed for $namespace during helm install step. Error: $error_message"
        continue
      fi

      # Send success email
      send_email "$namespace successfully upgrade" "$namespace is up and upgrade"

      # Sleep for 10 seconds before proceeding to the next namespace
      sleep 10
    done

    echo "Script completed."
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}
