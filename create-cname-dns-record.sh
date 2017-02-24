#!/bin/bash

# Create a CNAME record in the appropriate DNS zone on AWS Route 53
# Requires kubectl and cli53 from https://github.com/barnybug/cli53
# Ensure AWS profile is configured with access to update DNS records (e.g. AmazonRoute53FullAccess policy)
#
# Aaron Roydhouse <aaron@roydhouse.com>
# https://github.com/whereisaaron
# https://gist.github.com/whereisaaron/bc6c71bec99c493b1fc1ca3f9e8db4c1
#

#
# Parse options
#

display_usage ()
{
  echo "Usage: $0 --domain=<fqdn> --cname=<name>|--delete [--profile=<profile>] [--help]"
  echo "  Both a domain and CNAME are required to create"
  echo "  Default --profile is 'default'"
}

for i in "$@"
do
case $i in
    --domain=*)
    DOMAIN="${i#*=}"
    shift # past argument=value
    ;;
    --cname=*)
    CNAME="${i#*=}"
    shift # past argument=value
    ;;
    --profile=*)
    PROFILE="${i#*=}"
    shift # past argument=value
    ;;
    --delete)
    DELETE=true
    shift # part argument
    ;;
    --help)
    display_usage
    exit 0
    ;;
    *)
    # unknown option
    echo "Unknown option $1"
    display_usage
    exit 1
    ;;
esac
done

#
# Check options
#

PROFILE=${PROFILE:-default}

# Must specify and domain and one of cname or delete
if [[ -z "$DOMAIN" || ( -z "$CNAME" && -z "$DELETE" ) || ( -n "$CNAME" && -n "$DELETE" ) ]]; then
  display_usage
  exit 2
fi

#
# Remove one level from the front of a domain name
# Returns the rest of the domain name (success), or blank if nothing left (fail)
#
function get_base_name() {
    local HOSTNAME="${1}"

    if [[ "$HOSTNAME" == *"."* ]]; then
      HOSTNAME="${HOSTNAME#*.}"
      echo "$HOSTNAME"
      return 0
    else
      echo ""
      return 1
    fi
}

#
# Find the Route53 zone for this domain name
# Prefers the longest match, e.g. if creating 'a.b.foo.baa.com',
# a 'foo.baa.com' zone will be preferred over a 'baa.com' zone
# Returns the zone name (success) or nothing (fail)
#
function find_zone() {
  local DOMAIN="${1}" PROFILE=${2}

  local ZONELIST=$(cli53 list --profile "$PROFILE" --format json | jq --raw-output '.[].Name' | sed -e 's/\.$//' | xargs echo -n)

  local TESTDOMAIN="${DOMAIN}"

  while [[ -n "$TESTDOMAIN" ]]; do
    for zone in $ZONELIST; do
      if [[ "$zone" == "$TESTDOMAIN" ]]; then
        echo "$zone"
        return 0
      fi
    done
    TESTDOMAIN=$(get_base_name "$TESTDOMAIN")
  done

  return 1
}

#
# Find DNS zone and create record
#

ZONE=$(find_zone "$DOMAIN" "$PROFILE")

if [[ -z "$ZONE" ]]; then
  echo "Could not file a matching zone for '${DOMAIN}' with profile '${PROFILE}'"
  exit 3
fi

if [[ "$DELETE" != "true" ]]; then
  echo "Creating record in zone '${ZONE}'"
  cli53 rrcreate --profile "$PROFILE" --replace ${ZONE} "${DOMAIN}. CNAME ${CNAME}."
else
  echo "Deleting record in zone '${ZONE}'"
  cli53 rrdelete --profile "$PROFILE" ${ZONE} ${DOMAIN}. CNAME
fi
