Check list:

- [ ] PR description is meaningful.
- [ ] `./lock.sh` has run (when appropriate) and every changed `requirements.txt` is committed.
- [ ] `./check_docker.sh` lints `Dockerfile` with no findings.
- [ ] `./build_docker.sh` finishes with no `FAIL` in its summary.
- [ ] `./.github/smoke-images.sh` passes against the images just built.
- [ ] Zoose version in `.env` has been updated appropriately.
- [ ] Commit has been tagged `git tag X.Y.Z` with `X.Y.Z` as in `.env`.
- [ ] `README` has been updated (if applicable).
