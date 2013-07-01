# GitHub web hook auto pull service for PHP

__GitHub automatic pull script__ keeps your project's remote installation up-to-date by automatically pulling all changes pushed to that project's GitHub repository. All automatic pulls are logged into a file.

File __/var/www/projectName/repoData/git-auto-pulls.log__
```log
    ae2da0d420e790c7394fd4d7a8fb3726edf7135c - 2012-10-05T03:17:59-07:00 - Readme update - Konrad Gibaszewski
```

## Install

```bash
cd /var/www/projectName
git submodule add git@github.com:syncube/gitHub-autoPull-PHP.git repoData
git commit -m 'Added gitHub-autoPull-PHP as a submodule'
cd repoData
git fetch -a
git tag
git checkout 1.0.0
git commit -m 'Changed to gitHub-autoPull-PHP 1.0.0'
./initConfig.sh
```

## SSH configuration

For server side GitHub authentication it's convenient to use SSH public key authentication. We assume to operate in _/var/www/projectName_ as user __www-data__ whose .ssh configuration is located in _/var/www/.ssh/config_ . Github's SSH keys are stored here _not_ encrypted for convenience and usability. We can use one deployment key pair per repository.

### Generate new key pair
Save your newly generated key pair as ```id_rsa_github-projectName``` and ```id_rsa_github-projectName.pub```.

```bash
    cd /var/www/.ssh/
    ssh-keygen -t rsa
```

__Important!__ Do not forget to deploy public key by going to *[GitHub](https://github.com/) -> Project's Repository -> Admin -> Deploy keys -> Add deploy key*.

SSH configuration for user www-data. File __/var/www/.ssh/config__

```bash
  # General authentication with GitHub
  Host github.com
    User git
    HostName github.com
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/id_rsa_github
      
  Host projectName
    User git
    HostName github.com
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/id_rsa_github-projectName

  Host projectName2
    User git
    HostName github.com
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/id_rsa_github-projectName2
```

## .htpasswd 
Generate .htpasswd entry in __/var/www/.htpasswd__ for user projectUser with password projectPassword (SHA Encryption)

```bash
cd /var/www/
(PWD="projectPassword";SALT="$(openssl rand -base64 3)";SHA1=$(printf "$PWD$SALT" | openssl dgst -binary -sha1 | sed 's#$#'"$SALT"'#' | base64);printf "projectUser:{SSHA}$SHA1\n" >> .htpasswd)
```

## nginx configuration

Add password protect git-pull.php into the server section of vhost configuration.

File __/etc/nginx/sites-available/projectName__

```bash
server {

  ...

  # Disable viewing of hidden files
    location ~ /\. {
        deny  all;
    }

  # password protect /repoData
  location /repoData {
    auth_basic "GitHubPull";
    auth_basic_user_file /var/www/.htpasswd;
    
    satisfy any;
    
    # Allow your intern
    allow xxx.xxx.xxx.xxx;
    
    # Allow GitHub post-receive hook to call git-pull.php script
    # The IPs list varies from repo to repo and should be always updated
    # when creating new repository
    allow 50.57.128.197/32;
    allow 50.57.231.61/32;
    allow 108.171.174.178/32;
  }

  ...

}
```

## Apache2 configuration

Below you can find basic vhost configuration for Apache2 web server, with ```.htaccess``` files with preconfigured password protection for whole project and only for repoData/git-pull.php script. We also need to set up a bypass in Basic Authentication for our own and GitHub IPs.

File __/etc/apache2/sites-available/projectName__

```bash
<VirtualHost *>

    ...
    
    ServerName projectName.TLD
    DocumentRoot /var/www/projectName.TLD/

    ...

    <Directory /var/www/projectName/>
        Options -Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order Allow,Deny
        Allow from all
    </Directory>

    ...

</VirtualHost>
```

File __/var/www/projectName/.htaccess__

```htaccess
Order Deny,Allow
Deny from all

AuthName RestrictedAccess
AuthType Basic
Require valid-user
AuthUserFile /var/www/.htpasswd

Satisfy Any
```

File __/var/www/projectName/repoData/.htaccess__
```htaccess
<Files "git-pull.php">
  Order Deny,Allow
  Deny from all
  
  AuthName GitHubPull
  AuthType Basic
  Require valid-user
  AuthUserFile /var/www/.htpasswd
  
  # Allow your intern
  # Allow from xxx.xxx.xxx.xxx
  
  # Allow GitHub post-receive hook to call git-pull.php script
  # The IPs list varies from repo to repo and should be always updated
  # when creating new repository
  Allow from 50.57.128.197/32
  Allow from 50.57.231.61/32
  Allow from 108.171.174.178/32
  
  Satisfy Any
</Files>
```