# https://nixos.org/manual/nixos/unstable/index.html#ssec-machine-objects
with subtest("services are up"):
    machine.wait_for_unit("dev-solr")
    machine.wait_for_unit("postgresql")
    machine.wait_for_unit("mysql")
    machine.wait_for_unit("nginx")
    machine.wait_for_unit("exim")
    machine.wait_for_unit("dovecot2")
    machine.wait_for_unit("dev-fuseki")
