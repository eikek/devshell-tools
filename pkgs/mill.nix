{
  mill,
  jdk17,
  jdk21,
}: {
  mill17 = mill.override {jre = jdk17;};
  mill21 = mill.override {jre = jdk21;};
}
