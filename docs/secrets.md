# Secrets

As you may have noticed, nothing in this repository is a secret. There are no encrypted files. This is because we use 1Password to manage all of our secrets in the cluster. This is done via [1Password connect](https://developer.1password.com/docs/connect) and [external secrets operator](https://external-secrets.io/latest/).

In order to get this working as intended, there is one [provisioning step](./provisioning#installing-1password-authentication) that needs to run in order to add the required 1Password authentication into the cluster. Once that is done, everything else should be automated and ready to go.
