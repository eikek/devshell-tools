{
  mill,
  mill1,
  jdk17,
  jdk21,
}: {
  mill17 = mill.override {jre = jdk17;};
  mill21 = mill.override {jre = jdk21;};
  mill1_17 = mill1.override {jre = jdk17;};
  mill1_21 = mill1.override {jre = jdk21;};
}
