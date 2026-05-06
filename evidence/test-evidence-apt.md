# Evidence: APT Get Pull Test

**Date:** 2026-05-05
**Tester:** River

## Context
Wash's recently executed test successfully pulled a `.deb` package via `apt-get` from the local Pulp container registry. To adhere to our updated project directive 2026-05-05T00:00:00Z, we have captured visual evidence of the container registry running.

## Artifacts
* `pulp-apt-deb-repo.png` - Playwright CLI screenshot of the Pulp registry endpoints.

## Conclusion
The registry is verified to be up and running on port `8080`, supporting the package pull test.
