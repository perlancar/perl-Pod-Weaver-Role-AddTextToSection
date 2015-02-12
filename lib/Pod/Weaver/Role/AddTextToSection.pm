package Pod::Weaver::Role::AddTextToSection;

# DATE
# VERSION

use 5.010001;
use Moose::Role;

use Encode qw(decode encode);
use List::Util qw(first);
#use Pod::Elemental;
use Pod::Elemental::Element::Nested;

sub add_text_to_section {
    my ($self, $document, $text, $section, $opts) = @_;

    $opts //= {};
    $opts->{create} //= 1;
    $opts->{ignore} //= 0;
    $opts->{top} //= 0;

    # convert characters to bytes, which is expected by read_string()
    $text = encode('UTF-8', $text, Encode::FB_CROAK);

    my $text_elem = Pod::Elemental->read_string($text);

    my $section_elem = first {
        $_->can('command') && $_->command =~ /\Ahead\d+\z/ &&
            uc($_->{content}) eq uc($section) }
        @{ $document->children };#, @{ $input->{pod_document}->children };

    # this comment is from the old code, i'm keeping it here in case i need it

    # sometimes we get a Pod::Elemental::Element::Pod5::Command (e.g. empty
    # "=head1 DESCRIPTION") instead of a Pod::Elemental::Element::Nested. in
    # that case, just ignore it.

    if (!$section_elem) {
        if ($opts->{create}) {
            $self->log_debug(["Creating section $section"]);
            $section_elem = Pod::Elemental::Element::Nested->new({
                command  => 'head1',
                content  => $section,
            });
            push @{ $document->children }, $section_elem;
        } else {
            die "Can't find section named '$section' in POD document";
        }
    } else {
        $self->log_debug(["Skipping adding text because section $section already exists"]);
        return if $opts->{ignore};
    }

    if ($opts->{top}) {
        $self->log_debug(["Adding text at the top of section $section"]);
        unshift @{ $section_elem->children }, @{ $text_elem->children };
    } else {
        $self->log_debug(["Adding text at the bottom of section $section"]);
        push @{ $section_elem->children }, @{ $text_elem->children };
    }
}

no Moose::Role;
1;
# ABSTRACT: Add text to a section

=head1 SYNOPSIS

 my $text = <<EOT;
 This module is made possible by L<Krating Daeng|http://www.kratingdaeng.co.id>.

 A shout out to my man Punk The Man.

 Thanks also to:

 =over

 =item * my mom

 =item * my dog

 =item * my peeps

 =back

 EOT

 $self->add_text_to_section($document, $text, 'THANKS');


=head1 DESCRIPTION


=head1 METHODS

=head2 $obj->add_text_to_section($document, $text, $section[, \%opts])

Add a string C<$text> to a section named C<$section>.

C<$text> will be converted into a POD element tree first.

Section are POD paragraphs under a heading (C<=head1>, C<=head2> and so on).
Section name will be searched case-insensitively.

If section does not yet already exist: will create the section (if C<create>
option is true) or will die. Section will be created with C<=head1> heading at
the bottom of the document (XXX is there a use-case where we need to add at the
top and need to provide a create_top option? XXX is there a use-case where we
need to create C<head2> and so on?).

If section already exists, will skip and do nothing (if C<ignore> option is
true, not unlike C<INSERT OR IGNORE> in SQL) or will add text. Text will be
added at the bottom the existing text, unless when C<top> option is true in
which case will text will be added at the top the existing text.

Options:

=over

=item * create => bool (default: 1)

Whether to create section if it does not already exist in the document.

=item * ignore => bool (default: 0)

If set to true, then if section already exist will skip adding the text.

=item * top => bool (default: 0)

If set to true, will add text at the top of existing text instead of at the
bottom.

=back
