package lib::remote;

use 5.006;
use strict;
use warnings;
use LWP::UserAgent;
#~ use Carp qw(croak carp);

=encoding utf8

=head1 ПРИВЕТСТВИЕ SALUTE

Доброго всем! Доброго здоровья! Доброго духа!

Hello all! Nice health! Good thinks!

=cut

=head1 NAME

lib::remote - Удаленное использование модулей. Загружает исходник модуля с удаленного сервера. Одна манипуляция с @INC - C<push @INC, sub {};>. Диспетчер возвращает filehandle для контента, полученного удаленно. Смотреть perldoc -f require.

lib::remote - Perl pragma for use remote modules without installation basically throught protocols like http. One C<push @INC, sub {};> This dispather will return filehandle for downloaded content of a module from remote server. See perldoc -f require.

Идея из http://forum.codecall.net/topic/64285-perl-use-modules-on-remote-servers/

Кто-то еще стырил http://www.linuxdigest.org/2012/06/use-modules-on-remote-servers/ (поздняя дата и есть ошибки)

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 FAQ

Q: Зачем? Why?

A: За лосем. For elk.

Q: Почему? Why?

A: По кочану. For head of cabbage.


=head1 SYNOPSIS

Все просто, по аналогии с локальным вариантом:

    use lib '../to/any/local/lib';

указываем урл:

    use lib::remote 'http://<хост(host)>/site-perl/.../';
    use My::Module1;
    ...

Искомый модуль будет запрашиваться как в локальном варианте, дописывая в конце URL: http://<хост(host)>/site-perl/.../My/Module1.pm

Допустим, УРЛ сложнее, не содержит имени модуля или используются параметры: https://<хост>/.../?key=ede35ac1208bbf479&...

Тогда делаем пары ключ->значение, указывая КОНКРЕТНЫЙ урл для КОНКРЕТНОГО модуля, например:

    use lib::remote
        'http://....',
        'Some::Module1'=>'https://<хост>/.../?key=ede35ac1208bbf479&...',
        'SomeModule2'=>'ssh://user:pass@host:/..../SomeModule2.pm',
    ;
    #use Some::Module1; не нужно, уже сделано (см. L</"Конфигурация модуля">)
    use SomeModule2 qw(func1 func2);# только, если нужно что-то импортировать, простое use уже сделано (см. L</"Конфигурация модуля">)
    use parent 'Some::Module1';
    ...

Не трудно догадаться, что вычленение пар в общем списке происходит по специфике URI.

B<Внимание>

Конкретно указанный модуль (через пару) будет искаться сначала в своем урл, а потом в безымянных безключевых параметрах.

При многократном вызове use lib::remote все параметры и урлы сохраняются, аналогично use lib '';, но естественно не в @INC. Повторюсь, в @INC помещается только один диспетчер.

=head2 Расширенный синтаксис

    use lib::remote
        ['http://....', opt1 =>..., opt2 =>..., ....],
        'Some::Module1'=>['https://<хост>/...',....],
        'SomeModule2'=>['ssh://user@host:/..../SomeModule2.pm', 'pass'=>..., ...],
    ;
    ...

Видно, что URL передается первым элементом массива, остальные элементы как пары дополнительных опций.

Опции:

=over 4

=item * charset => 'utf-8', Задать кодировку урла. Если веб-сервер правильно выдает C<Content-Type: application/x-perl; charset=...>, тогда не нужно, ->decoded_content сработает. Помнить про C<use utf8;>

=item * что еще?

=back

=head2 Конфигурация модуля lib::remote

Просто передаем дополнительную пару ключ->значение:

    use lib::remote
        'lib::remote'=>[opt1 =>..., opt2 =>..., ....],
        ...
    ;
    ...

Видно, что ключ должен совпадать с именем этого модуля 'lib::remote'. Это и есть признак конфигурационных данных.

Основные опции:

=over 4

=item * autouse => 0. По умолчанию 1, т.е. для конкретных модулей 'Some::Module1'=> .... срабатывает use Some::Module1;

=item * что еще?

=back

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


=cut



my %config = (
    autouse =>1,
);
my $ua = LWP::UserAgent->new;
#~ $ua->timeout(10);
my %modules = ();#сохранение списка пар "Имя::модуля"=>[url]
my @base_ulrs = ();# сохранение общих путей

BEGIN {
    push @INC, sub {# диспетчер
        my $self = shift;# эта функция CODE(0xf4d728) вроде не нужна
        my $arg = shift;#Имя/Модуля.pm
        my $mod = $arg;
        $mod =~ s#/#::#g;
        $mod =~ s#\.pm$##g;
        #~ print "remote INC sub: module=[$mod]\n",;# lwpget: arg=[Имя/Модуля.pm] Имя::Модуля
        #~ return undef unless $url;
        my $content;
        if (my $m = $modules{$mod}) {# конкретный модуль
            my $url = ref($m) ? $m->[0] : $m;
            if ( $url =~ m#^(http|https|ftp|file)://# ) {#LWP
                $content = lwpget($url);
                #~ eval $content;
                #~ if ($@) {
                    #~ $url =~ s#/$##;
                    #~ $content = lwpget("$url/$arg");
                #~ }
            }
        }
        unless ($content) {# перебор удаленных папок
            for (@base_ulrs) {
                s#/$##;
                my $url = "$_/$arg";
                if ( $url =~ m#^(http|https|ftp|file)://# ) {#LWP
                    $content = lwpget($url);
                    last if $content;
                }
            }
        }
        return undef unless $content;
        
        open my $fh, '<', \$content or die "Cant open: $!";
        return $fh;
    };
}

sub import {
    my $pkg = shift;# is eq __PACKAGE__
    #~ my %arg = @_;
    #~ print "import: ", "arg1=[$pkg], args: ", (map {"[$_], ";} @_), "\n";
    my $module;
    my %new_mods = ();# для этого захода
    my %unique = @base_ulrs;
    map {# разбор аргументов
        if ( ref($_) || m#^\w+://# ) {
            if ($module) {
                if ( $module eq __PACKAGE__ ) {
                    my %opt = @$_;
                    map {$config{$_} = $opt{$_};} keys %opt;
                    #~ print "config:", %config, "\n";
                } else {
                    $new_mods{$module} = $_;
                }
                $module = undef;
            } else {
                #~ print "push base_url\n";
                push @base_ulrs, $_ unless $unique{$_}++;
            }
        } else {
            die "Неверный синтаксис. Для [$module] не указан URL" if $module;
            $module = $_;
        }
    } @_;
    
    map {
        $modules{$_} = $new_mods{$_};
        #~ my @opt = ref($modules{$_}) ? @{$modules{$_}} : ($modules{$_});
        #~ my $url = shift(@opt);
        #~ $url =~ s#/$##;
        #~ my %opt = @opt;
        #~ my $file =$url;
        #~ $file =~ s#::#/#g;
        if ( $config{autouse} ) {
            eval "use $_;";# вот сразу заход в диспетчер
            print "eval use $_;\n";
            if ($@) {
                warn "Возможно проблемы с модулем [$_]: $@";
            }
        }
    } keys %new_mods;
    #~ print "import: ", (map {"[$_]";} @base_ulrs), "\n";
}

sub lwpget {
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

=head1 AUTHOR

Mikhail Che, C<< <m.che[пёсик]aukama.dyndns.org> >>

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

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mikhail Che.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of lib::remote
