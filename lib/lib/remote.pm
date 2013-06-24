package lib::remote;

use 5.006;
use strict;
use warnings;
use LWP::UserAgent;
#~ use Data::Dumper;
#~ use Carp qw(croak carp);

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

my $ua = LWP::UserAgent->new;
my $url_re = qr#^(https?|ftp|file)://#i;
#~ $ua->timeout(10);
my %config = (#сохранение списка пар "Имя::модуля"=>{url => ..., ..., ...}
    __PACKAGE__ => {require=>1, cache=>1, debug=>0},
    __urls__ => [],# сохранение общих путей 
    __content__ => {},# cache
);

#~ my $pkg = 'lib::remote';

BEGIN {
    push @INC, sub {# диспетчер
        my $self = shift;# эта функция CODE(0xf4d728) вроде не нужна
        my $arg = shift;#Имя/Модуля.pm
        
        my $path = my $mod = $arg;
        $mod =~ s|/+|::|g;
        $mod =~ s|\.pm$||g;
        $path =~ s|::|/|g;
        $path =~ s|\.pm$||;
        $path .= '.pm';
        
        my $conf = $config{$mod};
        my $debug = ($conf && $conf->{debug}) // $config{__PACKAGE__}{debug};
        my $cache = ($conf && $conf->{cache}) // $config{__PACKAGE__}{cache};
        
        warn __PACKAGE__, ": try dispatch of [$mod][path=$path][arg=$arg]]" if $debug;
        
        if ($cache && $config{__content__}{$mod}) {
            warn __PACKAGE__, ": get cached content of [$mod]" if $debug;
            open my $fh, '<', \$config{__content__}{$mod} or die "Cant open: $!";
            return $fh;
        }

        my $content;
        
        if ($conf && $conf->{url} && $conf->{url} =~ /$url_re/) {# конкретный модуль
            #~ warn "Неверный или кривой урл[$m->{url}] для модуля [$mod]"
                #~ and return undef
                #~ unless $m->{url} && $m->{url} =~ /$url_re/;
            $content = _lwpget($conf->{url});
            warn __PACKAGE__, ": couldn't get content the module [$mod] by link [$conf->{url}]" if $debug && !$content;
        }
        unless ($content) {# перебор удаленных папок
            
            for (@{$config{__urls__}}) {
                s|/$||;
                warn __PACKAGE__, ": try get [$_/$path] for [$mod]" if $debug;#": get [$mod] content";
                $content = _lwpget("$_/$path");
                if ($content) {
                    warn __PACKAGE__, ": success LWP get content [$mod] by link [$_/$path]" if $debug;#": get [$mod] content";
                    last;
                }
            }
        }
        
        return undef unless $content;
        
        $config{__content__}{$mod} = $content if $cache ;

        open my $fh, '<', \$content or die "Cant open: $!";
        return $fh;
    };
}

sub import { # это разбор аргументов после строк use lib::remote ...
    my $pkg = shift;# is eq __PACKAGE__
    $pkg->config(@_);
    my $last_modules = delete $config{__PACKAGE__}{_last_modules}
        or return;
    
    my $module;
    for my $module (@$last_modules) {
        my $require = $config{$module}{require} // $config{__PACKAGE__}{require};
        my $debug = $config{$module}{debug} // $config{__PACKAGE__}{debug};
        if ( $require ) {
            #~ eval "use $module;";# вот сразу заход в диспетчер @INC
            eval {require $module};
            if ($@) {
                warn __PACKAGE__, ": возможно проблемы с модулем [$module]: $@";
            } elsif ($debug) {
                warn __PACKAGE__, ": success done [require $module]\n"  if $debug;
            }
        }
        my $import = $config{$module}{import};# || $config{__PACKAGE__}{import};
        
        if ($require && $import && @$import) {
            eval {$module->import(@$import)};
            if ($@) {
                warn __PACKAGE__, ": возможно проблемы с импортом [$module]: $@";
            } else {
                warn __PACKAGE__, ": success done [$module->import(@{[@$import]})]\n" if $debug;
            }
        }
    }
}

sub config {
    my $pkg = shift;# is eq __PACKAGE__
    my $module;
    for my $arg (@_) {
        my $opt = _opt($arg);
        if ($module) {
            if ( $module eq '__PACKAGE__' ) {
                my $url = delete $opt->{url};
                push @{$config{__urls__}}, $url if $url && $url =~ /$url_re/ && !($url ~~ @{$config{__urls__}});
            } else {
                push @{$config{__PACKAGE__}{_last_modules}}, $module;
            }
            @{$config{$module}}{keys %$opt} = values %$opt;
            $module = undef; # done pair
        } elsif ($opt->{url} && $opt->{url} =~ /$url_re/) {
            push @{$config{__urls__}}, $opt->{url} unless $opt->{url} ~~ @{$config{__urls__}};#$unique{$arg}++;
        } elsif (!ref($arg)) {
            $module = $arg;
        } else {
            @{$config{__PACKAGE__}}{keys %$opt} = values %$opt;
        }
    }
    return \%config;
}

sub _opt {
    my $arg  = shift;
    my $ret = {url=>$arg,} unless ref($arg);
    $ret ||= {$arg->[0] =~ /$url_re/ ? (url=>@$arg) : @$arg,} if ref($arg) eq 'ARRAY';
    $ret ||= $arg if ref($arg) eq 'HASH';
    return $ret;
}

sub _lwpget {
    my $url = shift;
    #~ print "get: $self";
    my $get = $ua->get($url);
    if ( $get->is_success ) {
        #~ print "lwpget success [$url]\n";
        return $get->decoded_content();# ??? ->content нужно отладить charset=>'cp-1251'
    } else {
        #~ die "LWP::UserAgent->get($url) failed: ". $module->status_line."\n";
        return undef;
    }
}

=encoding utf8

=head1 ПРИВЕТСТВИЕ SALUTE

Доброго всем! Доброго здоровья! Доброго духа!

Hello all! Nice health! Good thinks!


=head1 NAME

lib::remote - Удаленное использование модулей. Загружает модули с удаленного сервера. Только один диспетчер в @INC- C<push @INC, sub {...};>. Диспетчер возвращает filehandle для контента, полученного удаленно. Смотреть perldoc -f require.

lib::remote - pragma for use remote modules without installation basically throught protocols like http. One dispather on @INC - C<push @INC, sub {};> This dispather will return filehandle for downloaded content of a module from remote server. See perldoc -f require.

Идея из L</http://forum.codecall.net/topic/64285-perl-use-modules-on-remote-servers/>

Кто-то еще стырил L</http://www.linuxdigest.org/2012/06/use-modules-on-remote-servers/> (поздняя дата и есть ошибки)




=head1 FAQ

Q: Зачем? Why?

A: За лосем. For elk.

Q: Почему? And why?

A: По кочану. For head of cabbage.

Q: Как?

A: Да вот так.


=head1 SYNOPSIS

Все просто. По аналогии с локальным вариантом:

    use lib '/to/any/local/lib';

указываем урл:

    use lib::remote 'http://<хост(host)>/site-perl/.../';
    use My::Module1;
    ...

Искомый модуль будет запрашиваться как в локальном варианте, дописывая в конце URL: http://<хост(host)>/site-perl/.../My/Module1.pm

Допустим, УРЛ сложнее, не содержит имени модуля или используются параметры: https://<хост>/.../?key=ede35ac1208bbf479&...

Тогда делаем пары ключ->значение, указывая КОНКРЕТНЫЙ урл для КОНКРЕТНОГО модуля, например:

    use lib::remote
        'Some::Module1'=>'https://<хост>/.../?key=ede35ac1208bbf479&...',
        'SomeModule2'=>'ssh://user:pass@host:/..../SomeModule2.pm',
    ;
    #use Some::Module1; не нужно, уже сделано require (см. "Опцию [require] расширенного синтаксиса")
    use SomeModule2 qw(func1 func2), [<what ever>, ...];# только, если нужно что-то импортировать очень сложное (см. "Опцию [import] расширенного синтаксиса")
    use parent 'Some::Module1'; # такое нужно
    ...


B<Внимание>

Конкретно указанный модуль (через пару) будет искаться сначала в своем урл, а потом во всех заданных урлах глобального конфига.

При многократном вызове use lib::remote все параметры и урлы сохраняются, аналогично use lib '';, но естественно не в @INC. Повторюсь, в @INC помещается только один диспетчер.

=head2 Расширенный синтаксис

    use lib::remote
        # global config for modules unless them have its own
        'http://....',
        ['http://....', opt1 =>..., opt2 =>..., ....],
        {url=>'http://....', opt1 =>..., opt2 =>..., ....},

    # per module personal options
        'Some::Module1'=> 'http://....',
        'Some::Module2'=>['http://...', opt1 =>..., opt2 =>..., ....],
        'Some::Module3'=>{url => 'http://...', opt1 =>..., opt2 =>..., ....},
        'SomeModule1'=>['ssh://user@host:/..../SomeModule2.pm', 'pass'=>..., ...],
        'SomeModule2'=>{url => 'ssh://user@host:/..../SomeModule2.pm', 'pass'=>..., ...},
    ;
    ...


Не трудно догадаться, что вычленение пар в общем списке происходит по специфике URI.

Опции:

=over 4

=item * url => '>schema://>...' Это основной параметр. На уровне глобальной конфигурации сохраняется список всех урлов, к которым добавляется путь Some/Module.pm

=item * charset => 'utf8', Задать кодировку урла. Если веб-сервер правильно выдает C<Content-Type: ...; charset=utf8>, тогда не нужно, ->decoded_content сработает. Помнить про C<use utf8;>

=item * require => 1|0 Cрабатывает require Some::Module1; Поэтому не нужно делать строку use|require Some::Module;, если только нет хитрых импортов (см. опцию import ниже)

=item * import => [qw(), ...]. The import spec for loaded module. Disadvantage!!! Work on list of scalars only!!! Просто вызывается Some::Module1->import(...);

=item * cache => 1|0 Content would be cached

=item * debug => 0|1 warn messages

=item * что еще?

=back


Можно многократно вызывать use lib::remote ...; и тем самым изменять настройки модулей и глобальные опции.


=head1 Требования REQUIRES

Если урлы 'http://...', 'https://...', 'ftp://...', 'file://...', то нужен LWP::UserAgent

Если 'ssh://...' - TODO

Url может возвращать сразу пачку модулей (package). В этом случае писать ключом один модуль и дополнительно вызывать use для остальных модулей.

=head1 EXPORT

Ничего не экспортируется.

=head1 SUBROUTINES/METHODS

Только внутренние.

=head1 Пример конфига для NGINX, раздающего модули:

    ...
    server {
        listen       81;
#        server_name  localhost;


        location / {
            charset utf-8;
            charset_types *;
            root   /home/perl/lib-remote/;
            index  index.html index.htm;
        }

    }
    ...


=head1 AUTHOR

Mikhail Che, C<< <m[пёсик]cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lib-remote at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=lib-remote>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc lib::remote


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=lib-remote>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/lib-remote>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/lib-remote>

=item * Search CPAN

L<http://search.cpan.org/dist/lib-remote/>

=back


=head1 ACKNOWLEDGEMENTS

Не знаю.

=head1 SEE ALSO

Глянь L<PAR>

Глянь L<Remote::Use>

Глянь L<lib::http>

Глянь L<lib::dbi>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Mikhail Che.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 DISTRIB

$ module-starter --module=lib::remote --author=”Mikhail Che” --email=”m.che@cpan.org" --builder=Module::Build --license=perl --verbose

$ perl Build.PL

$ ./Build test

$ ./Build dist


=cut

1; # End of lib::remote
