export GITLAB_HOME=/srv/gitlab
export GITLAB_HOSTNAME=ec2-3-21-75-55.us-east-2.compute.amazonaws.com
export GITLAB_EXTERNAL_URL=http://$GITLAB_HOSTNAME:6990
docker-compose -f docker-compose.yml up -d