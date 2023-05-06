# pull gitlab-runner images
docker pull gitlab/gitlab-runner:latest

# run container
docker run -d \
  --name gitlab-runner \
  --restart always \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest

# registeration
docker exec -it {container_id} /bin/bash
gitlab-runner register
