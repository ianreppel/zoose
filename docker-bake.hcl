// One build graph for every Zoose image. `docker buildx bake --load` builds the targets
// in parallel, and each flavour pulls only its own base stage, so nothing waits on a
// published image or on a hand-ordered list of commands.
//
//   docker buildx bake --load              // all five images
//   docker buildx bake --load quantum      // one image, base built as a dependency
//   docker buildx bake --load --set *.max-parallel=4   // cap concurrency
//
// PREFIX and TAG come from the environment (build_docker.sh sources .env first).

variable "PREFIX" {
  default = "databaseline/zoose"
}

variable "TAG" {
  default = "6.0.0"
}

group "default" {
  targets = ["base", "neo4j", "pytorch", "quantum", "geo"]
}

// The registry cache is additive: it speeds a rebuild without changing what is built.
// Set ZOOSE_CACHE=1 to push and pull it; leave it unset for a fully local build.
target "_common" {
  dockerfile = "Dockerfile"
  context    = "."
}

target "base" {
  inherits = ["_common"]
  target   = "base"
  tags     = ["${PREFIX}-base:${TAG}", "${PREFIX}-base:latest"]
}

target "neo4j" {
  inherits = ["_common"]
  target   = "neo4j"
  tags     = ["${PREFIX}-neo4j:${TAG}", "${PREFIX}-neo4j:latest"]
}

target "pytorch" {
  inherits = ["_common"]
  target   = "pytorch"
  tags     = ["${PREFIX}-pytorch:${TAG}", "${PREFIX}-pytorch:latest"]
}

target "quantum" {
  inherits = ["_common"]
  target   = "quantum"
  tags     = ["${PREFIX}-quantum:${TAG}", "${PREFIX}-quantum:latest"]
}

target "geo" {
  inherits = ["_common"]
  target   = "geo"
  tags     = ["${PREFIX}-geo:${TAG}", "${PREFIX}-geo:latest"]
}




