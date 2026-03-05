%global ver %{?ver}%{!?ver:1.0}
%global rel %{?rel}%{!?rel:1}
%global cxxflags %{?cxxflags}%{!?cxxflags:-O2 -g -std=c++17 -Wall -Wextra -Werror -Wno-unused-parameter}
%global ldlibs %{?ldlibs}%{!?ldlibs:-lfmt}

Name:           release-test
Version:        %{ver}
Release:        %{rel}%{?dist}
Summary:        Small demo service that prints "Alive" every 5 seconds
License:        UNLICENSED
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  rpm-build
BuildRequires:  gcc-c++
BuildRequires:  fmt-devel
BuildRequires:  systemd-rpm-macros

Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd

%description
release-test is a tiny C++ program used for build/release packaging exercises.

%prep
%autosetup -n %{name}-%{version}

%build
%{__cxx} %{cxxflags} src/main.cpp -o %{name} %{ldlibs}

%install
rm -rf %{buildroot}
install -D -m 0755 %{name} %{buildroot}%{_bindir}/%{name}
install -D -m 0644 packaging/systemd/%{name}.service %{buildroot}%{_unitdir}/%{name}.service

%post
%systemd_post %{name}.service
if [ $1 -eq 1 ]; then
    /bin/systemctl enable --now %{name}.service >/dev/null 2>&1 || :
else
    /bin/systemctl try-restart %{name}.service >/dev/null 2>&1 || :
fi

%preun
if [ $1 -eq 0 ]; then
    /bin/systemctl disable --now %{name}.service >/dev/null 2>&1 || :
fi
%systemd_preun %{name}.service

%postun
%systemd_postun_with_restart %{name}.service

%files
%{_bindir}/%{name}
%{_unitdir}/%{name}.service

%changelog
* Sat Feb 28 2026 Eduard Basov <ebasov@ispmanager.com> - 1.6-1
- Fix masked service

* Sat Feb 28 2026 Eduard Basov <ebasov@ispmanager.com> - 1.5-1
- Fix start service on deb distr

* Sat Feb 28 2026 Eduard Basov <ebasov@ispmanager.com> - 1.4-1
- Fix start service for RPM-based distr

* Sat Feb 28 2026 Eduard Basov <ebasov@ispmanager.com> - 1.3-1
- Fix typo

* Sat Feb 28 2026 Eduard Basov <ebasov@ispmanager.com> - 1.2-1
- Fix build

* Sat Feb 28 2026 Eduard Basov <ebasov@ispmanager.com> - 1.1-1
- Build improvement

* Sat Feb 28 2026 Eduard Basov <ebasov@ispmanager.com> - 1.0-1
- Init Build For Ispmanager
