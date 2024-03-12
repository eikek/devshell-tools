{
  sbt,
  jdk11,
  jdk17,
  jdk21,
}: {
  sbt11 = sbt.override {jre = jdk11;};
  sbt17 = sbt.override {jre = jdk17;};
  sbt21 = sbt.override {jre = jdk21;};
}
