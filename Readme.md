# This is the TESTING environment of studip docker

To make testing branches as smooth as possible. Please have docker and docker-compose installed on your machine.

- Windows: https://docs.docker.com/docker-for-windows/install/
- Mac: https://docs.docker.com/docker-for-mac/install/

To setup a new test environment simply modify:

1. Checkout this branch
2. Modify **BRANCH: dev-branches/StEP00349** in *docker-compose.yml* to the branch you want to test.
3. Call `docker-compose build --no-cache` to make sure you build the correct branch
4. Use `docker-compose up -d` to start your Stud.IP
5. Goto http://localhost:80 and start your test
6. Use `docker-compose down` to stop Stud.IP