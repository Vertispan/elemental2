#!/bin/bash -i
#
# Build Elemental's jar files with Bazel.
#
# The script can take one argument that represents the path to the directory
# where the resulting jar files will be copied. If no argument is provided,
# the script will use a temporary directory.

set -e

BAZEL=${BAZEL:-bazel}

create_artifact() {
  jar cf $1 .
  mv $1 $2
}

artifact_directory=$1

if [[ -z "${artifact_directory}" ]]; then
  artifact_directory="$(mktemp -d)"
fi

if [[ ! -d "${artifact_directory}" ]]; then
  echo "Error: ${artifact_directory} is not a directory."  >&2
  exit 1
fi

bazel_root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
declare -a elemental_artifacts=(core dom indexeddb media promise svg webgl webstorage)

for artifact in "${elemental_artifacts[@]}"; do
  artifact_path="${bazel_root}/bazel-bin/java/elemental2/${artifact}"
  artifact_bazel_path="//java/elemental2/${artifact}"
  jar_file="lib${artifact}.jar"
  src_jar="lib${artifact}-src.jar"

  # ask bazel to explicitly build both jar files
  pushd "${bazel_root}"
  ${BAZEL} build "${artifact_bazel_path}:${jar_file}"
  ${BAZEL} build "${artifact_bazel_path}:${src_jar}"
  popd

  tmp_directory="$(mktemp -d)"
  pushd "${tmp_directory}"

  # extract src and class files in order to merge them in one jar.
  jar xf "${artifact_path}/${src_jar}"
  jar xf "${artifact_path}/${jar_file}"

  jar cf "elemental2-${artifact}.jar" .
  popd

  yes | mv "${tmp_directory}/elemental2-${artifact}.jar" "${artifact_directory}"
  echo "elemental2-${artifact}.jar created in ${artifact_directory}"

  yes | mv "${artifact_path}/${src_jar}" "${artifact_directory}/elemental2-${artifact}-sources.jar"
  echo "elemental2-${artifact}-sources.jar created in ${artifact_directory}"

  rm -rf "${tmp_directory}"
done
