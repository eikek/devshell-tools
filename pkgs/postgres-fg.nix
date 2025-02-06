{
  writeShellScriptBin,
  postgresql,
}:
# A simple startup script for postgresql running in foreground.
writeShellScriptBin "postgres-fg" ''
  data_dir="$1"
  port="''${2:-5432}"

  if [ -z "$data_dir" ]; then
      echo "A data directory is required!"
      exit 1
  fi

  if ! [ -f "$data_dir/PG_VERSION" ]; then
      echo "Initialize postgres cluster…"
      mkdir -p "$data_dir"
      chmod -R 700 "$data_dir"
      ${postgresql}/bin/pg_ctl init -D "$data_dir"
  fi

  exec ${postgresql}/bin/postgres -D "$data_dir" -k /tmp -h localhost -p $port
''
