locals {
  env_value = {
    "1" = "BXS"
    "2" = "INTEGRATION"
    "3" = "CPA"
  }
}

locals {
  select_env_name = lookup(var.env_mapping, var.select_env)
}

output "selected_env_type" {
  value = local.env_value[var.env_type]
}

output "selected_env" {
  value = local.select_env_name
}

resource "null_resource" "run_query_and_display_version" {
  triggers = {
    always_run = timestamp() # Force recreation on every apply
  }

  provisioner "local-exec" {
    command = <<EOT
      set -e  # Exit on any error

      log_file="/home/localstudio/db_scripts_upgrade/log/${local.select_env_name}_${local.env_value[var.env_type]}_$(date +%Y_%m_%d_%H%M%S).log"
      echo "DB scripts upgrade started at $(date)" >> $log_file

      # Pull latest database scripts
      cd /home/db_scripts/database-scripts/ && git pull https://github.com/neeweebodhee/database-scripts.git

      # Configure database parameters
      export PGPASSWORD="${lookup(var.db_credentials[local.select_env_name], "password")}"
      ssl_root_cert="${lookup(var.db_credentials[local.select_env_name], "sslrootcert")}"
      ssl_cert="${lookup(var.db_credentials[local.select_env_name], "sslcert")}"
      ssl_key="${lookup(var.db_credentials[local.select_env_name], "sslkey")}"
      db_host="${lookup(var.db_credentials[local.select_env_name], "host")}"
      db_port="${lookup(var.db_credentials[local.select_env_name], "port")}"
      db_user="${lookup(var.db_credentials[local.select_env_name], "username")}"
      db_name="${lookup(var.db_credentials[local.select_env_name], "database")}"

      # Determine query and script directory based on env_type
      case "${var.env_type}" in
        "1")
          query="SELECT max(db_ver_number) FROM bodhee.version_history;"
          scripts_dir="/home/db_scripts/database-scripts/Studio-Pre-Release"
          ;;
        "2")
          query="SELECT max(db_ver_number) from bodhee.version_history where db_ver ilike '%i' ;"
          scripts_dir="/home/db_scripts/database-scripts/Integration-Release/Integration-pre-release"
          ;;
        "3")
          query="SELECT max(db_ver_number) FROM bodhee.cpa_version_history;"
          scripts_dir="/home/db_scripts/database-scripts/CPA"
          ;;
        *)
          echo "Error: Unsupported application type ${var.env_type}" >> $log_file
          exit 1
          ;;
      esac

      # Run query to fetch current version
      echo "Identifying current DB version Running" >> $log_file
      current_version=$(psql "sslmode=verify-ca sslrootcert=$ssl_root_cert sslcert=$ssl_cert sslkey=$ssl_key host=$db_host port=$db_port user=$db_user dbname=$db_name" --tuples-only --no-align -c "$query")
      echo "Current Version: $current_version" >> $log_file

      # Save current version to a file
      echo $current_version > /home/localstudio/db_scripts_upgrade/current_version.txt

      # Check if target version is valid
      echo "Target Version: ${var.target_version}" >> $log_file
      if [ "$(printf '%s\n' "${var.target_version}" "$current_version" | sort -V | head -n1)" = "${var.target_version}" ] && [ "${var.target_version}" != "$current_version" ]; then
        echo "Target version ${var.target_version} is less than current version $current_version. Skipping upgrade." >> $log_file
        exit 0
      fi

      # Navigate to scripts directory
      cd $scripts_dir

      # Check if the target version script exists
      if [ ! -f "${var.target_version}" ]; then
        echo "Error: Target version script ${var.target_version} not found in path!" >> $log_file
        exit 1
      fi

      # Execute SQL scripts in order
      SCRIPTS=$(ls -1 *.sql | sort -V)
      START_EXEC=$([ "$current_version" = "0" ] && echo true || echo false)

      for SCRIPT in $SCRIPTS; do
        if [ "$SCRIPT" = "$current_version.sql" ]; then
          START_EXEC=true
          continue
        fi
        if $START_EXEC; then
          echo "Executing $SCRIPT..." >> $log_file
          psql "sslmode=verify-ca sslrootcert=$ssl_root_cert sslcert=$ssl_cert sslkey=$ssl_key host=$db_host port=$db_port user=$db_user dbname=$db_name" -f "$SCRIPT" -v ON_ERROR_STOP=1 >> $log_file 2>&1
          if [ $? -ne 0 ]; then
            echo "Error: DB upgrade failed for script $SCRIPT. Stopping execution." >> $log_file
            exit 1
          fi
        fi
        if [ "$SCRIPT" = "${var.target_version}" ]; then
          echo "Reached target version ${var.target_version}. Stopping execution." >> $log_file
          break
        fi
      done

      echo "DB scripts update finished at $(date)" >> $log_file
    EOT
  }
}
