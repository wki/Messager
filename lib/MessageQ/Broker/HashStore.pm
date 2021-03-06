package MessageQ::Broker::HashStore;
use Carp;
use Moose;
use MessageQ::Broker::HashStoreMessage;
use MessageQ::Broker::HashStoreQueue;
use namespace::autoclean;

extends 'MessageQ::Broker';

# queue_name => HashStoreQueue
has queue_for => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { +{} },
);

has consuming_queue => (
    is        => 'rw',
    isa       => 'MessageQ::Broker::HashStoreQueue',
    predicate => 'is_consuming',
);

=head1 NAME

MessageQ::Broker::HashStore - a dummy broker just good enough for testing

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

=head2 queue

returns a queue object for a given queue name

=cut

sub queue {
    my ($self, $queue_name) = @_;
    
    $self->queue_for->{$queue_name} //= MessageQ::Broker::HashStoreQueue->new();
}

=head2 publish ( $destination, \%data )

=cut

sub publish {
    my ($self, $destination, $data) = @_;
    
    # strip off everything after first colon to get a clean queue name
    $destination =~ s{:.*\z}{}xms;
    $self->queue($destination)->add_message($data);
}

=head2 consume ( $queue )

tell the queue that this process wants to consume it

=cut

sub consume {
    my ($self, $queue) = @_;
    
    $self->consuming_queue($self->queue($queue));
}

=head2 receive

receive the next message from a consuming queue. Should block until a message
is present.

The simple HashStore will return undef as an indication that the queue
has expired.

=cut

sub receive {
    my $self = shift;
    
    croak 'not consuming to a queue -- receive not allowed'
        if !$self->is_consuming;
    
    my $data = $self->consuming_queue->first_message
        or return;
    
    return MessageQ::Broker::HashStoreMessage->new(
        queue => $self->consuming_queue,
        data  => $data,
    );
}

=head2 has_message

tell if a message is present.

=cut

sub has_message {
    my $self = shift;
    
    croak 'not consuming to a queue -- has_message not allowed'
        if !$self->is_consuming;
    
    return $self->consuming_queue->has_messages;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 AUTHOR

Wolfgang Kinkeldei, E<lt>wolfgang@kinkeldei.deE<gt>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
