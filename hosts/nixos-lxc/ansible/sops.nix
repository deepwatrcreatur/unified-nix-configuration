_:
{
  systemd.tmpfiles.rules = [
    "d /var/lib/sops/age 0755 ansible ansible -"
    "f /var/lib/sops/age/key.txt 0600 ansible ansible -"
  ];
}
