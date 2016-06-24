package: Perl-modules
version: "1.0"
env:
  SSL_CERT_FILE: "$(export PYTHONPATH=$PYTHON_MODULES_ROOT/lib/python2.7/site-packages:$PYTHONPATH; export PATH=$PYTHON_ROOT/bin:$PATH; export LD_LIBRARY_PATH=$PYTHON_ROOT/lib:$LD_LIBRARY_PATH; python -c \"import certifi; print certifi.where()\")"
prepend_path:
  PERLLIB: $PERL_MODULES_ROOT/lib/perl5
  PERL5LIB: $PERL_MODULES_ROOT/lib/perl5
---
#!/bin/bash -ex

mkdir -p $INSTALLROOT

cat << EOF > MyConfig.pm
\$CPAN::Config = {
  'applypatch' => q[],
  'auto_commit' => q[0],
  'build_cache' => q[100],
  'build_dir' => q[$BUILDDIR/.cpan/build],
  'build_dir_reuse' => q[0],
  'build_requires_install_policy' => q[yes],
  'bzip2' => q[/bin/bzip2],
  'cache_metadata' => q[1],
  'check_sigs' => q[0],
  'colorize_output' => q[0],
  'commandnumber_in_prompt' => q[1],
  'connect_to_internet_ok' => q[1],
  'cpan_home' => q[$BUILDDIR/.cpan],
  'ftp_passive' => q[1],
  'ftp_proxy' => q[],
  'getcwd' => q[cwd],
  'gpg' => q[/usr/bin/gpg],
  'gzip' => q[/bin/gzip],
  'halt_on_failure' => q[0],
  'histfile' => q[$BUILDDIR/.cpan/histfile],
  'histsize' => q[100],
  'http_proxy' => q[],
  'inactivity_timeout' => q[0],
  'index_expire' => q[1],
  'inhibit_startup_message' => q[0],
  'keep_source_where' => q[$BUILDDIR/.cpan/sources],
  'load_module_verbosity' => q[none],
  'make' => q[/usr/bin/make],
  'make_arg' => q[],
  'make_install_arg' => q[],
  'make_install_make_command' => q[/usr/bin/make],
  'makepl_arg' => q[INSTALL_BASE=$INSTALLROOT INSTALLMAN1DIR=$INSTALLROOT/lib/perl5/man1 INSTALLMAN3DIR=$INSTALLROOT/lib/perl5/man3 INSTALLSITEMAN3DIR=$INSTALLROOT/lib/perl5/man3],
  'mbuild_arg' => q[INSTALL_BASE=$INSTALLROOT INSTALLMAN1DIR=$INSTALLROOT/lib/perl5/man1 INSTALLMAN3DIR=$INSTALLROOT/lib/perl5/man3 INSTALLSITEMAN3DIR=$INSTALLROOT/lib/perl5/man3],
  'mbuild_install_arg' => q[INSTALL_BASE=$INSTALLROOT INSTALLMAN1DIR=$INSTALLROOT/lib/perl5/man1 INSTALLMAN3DIR=$INSTALLROOT/lib/perl5/man3 INSTALLSITEMAN3DIR=$INSTALLROOT/lib/perl5/man3],
  'mbuild_install_build_command' => q[./Build],
  'mbuildpl_arg' => q[--installdirs site],
  'no_proxy' => q[],
  'pager' => q[/usr/bin/less],
  'patch' => q[/usr/bin/patch],
  'perl5lib_verbosity' => q[none],
  'prefer_external_tar' => q[1],
  'prefer_installer' => q[MB],
  'prefs_dir' => q[$BUILDDIR/.cpan/prefs],
  'prerequisites_policy' => q[follow],
  'recommends_policy' => q[1],
  'scan_cache' => q[atstart],
  'shell' => q[/bin/bash],
  'show_unparsable_versions' => q[0],
  'show_upload_date' => q[0],
  'show_zero_versions' => q[0],
  'suggests_policy' => q[0],
  'tar' => q[/bin/tar],
  'tar_verbosity' => q[none],
  'term_is_latin' => q[1],
  'term_ornaments' => q[1],
  'test_report' => q[0],
  'trust_test_report_history' => q[0],
  'unzip' => q[/usr/bin/unzip],
  'urllist' => [q[http://www.cpan.org/]],
  'use_prompt_default' => q[0],
  'use_sqlite' => q[0],
  'version_timeout' => q[15],
  'wget' => q[/usr/bin/wget],
  'yaml_load_code' => q[0],
  'yaml_module' => q[YAML],
};
1;
__END__
EOF

cpan -j MyConfig.pm Net::Domain
PACKAGES="Test::MockModule Archive::Zip Authen::PAM Cache::Cache Class::ErrorHandler
          Class::Inspector Class::Load Class::MethodMaker Class::Singleton Clone
          Config::ApacheFormat Convert::ASN1 Convert::PEM Convert::UU Crypt::CBC Crypt::DES
          Crypt::DES_EDE3 Crypt::OpenSSL::RSA Crypt::OpenSSL::Random Crypt::OpenSSL::X509
          Crypt::SSLeay DBD::CSV DBD::Oracle DBD::SQLite DBI DateTime DateTime::Locale
          DateTime::TimeZone Digest::HMAC Digest::SHA1 Email::Date::Format Email::Find
          Email::Valid Error Expect Exporter::Lite File::CacheDir Filesys::DiskFree
          Filesys::DiskUsage Getargs::Long Getopt::Declare HTML::FromText HTML::Parser
          HTML::Tagset IO::Pipely IO::Socket::SSL IO::stringy IO::Tty List::MoreUtils
          LockFile::Simple Log::Agent Log::Agent::Rotate Log::Dispatch Log::TraceMessages
          MIME::Base64 MIME::Lite MIME::Types MIME::tools MailTools Net::DNS Net::Daemon Net::IP
          Net::SSLeay POE POE::Test::Loops Params::Util Params::Validate PlRPC SOAP::Lite
          SOAP::Transport::TCP SQL::Statement Sub::Uplevel Task::Weaken Term::ReadLine::Gnu
          Test::Deep Test::Exception Test::Fatal Test::NoWarnings Test::Pod Test::Simple
          Test::Tester Test::Warn Text::CSV_XS Tie::CPHash TimeDate Tree::DAG_Node Try::Tiny
          URI XML::Filter::BufferText XML::Generator XML::NamespaceSupport XML::Parser
          XML::Parser::EasyTree XML::SAX XML::SAX::Base XML::SAX::Writer XML::Simple libwww::perl
          perl perl::ldap uuid"

export PERL5LIB=$INSTALLROOT/lib/perl5


for x in $PACKAGES; do
  echo "Getting $x from CPAN"
  cpan -j MyConfig.pm $x
done

