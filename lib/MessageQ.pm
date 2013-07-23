package MessageQ;
use Moose;
use namespace::autoclean;

=head1 NAME

MessageQ - simple message exchange using a RabbitMQ backend

=head1 SYNOPSIS

    # sender
    
    use MessageQ;
    
    my $m = MessageQ->new(
        connect_options => {
            host     => 'localhost',
            user     => 'worker',
            password => 'worker',
        },
        broker_class => 'RabbitMQPP', # MessageQ::Broker::RabbitMQPP
    );
    
    $m->publish(queue_name => { message => 'structure', with => 'info' });
    
    # additional info (RabbitMQ: routing key) appended to queue name
    $m->publish('render:proof.de_DE' => { ... });


    # reveiver:
    
    use MessageQ;
    
    my $m = MessageQ->new(
        connect_options => {
            host     => 'localhost',
            user     => 'worker',
            password => 'worker',
        },
    );
    
    $m->consume('queue_name');
    
    while (my $message = $m->receive) {
        # do something with $message->data
        
        $message->ack; # or $message->reject;
    }
    
    # if we reach this point the connection got torn down

=head1 DESCRIPTION

=head1 ATTRIBUTES

=cut

has connect_options => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
);

has broker_class => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'MessageQ::Broker::RabbitMQPP',
);

has broker => (
    is         => 'ro',
    isa        => 'Object',
    lazy_build => 1,
    handles    => [qw(
        connect disconnect
        publish delegate 
        consume receive has_message
    )],
);

sub _build_broker {
    my $self = shift;
    
    # TODO: check if prefix with 'MessageQ::Broker::' makes sense.
    require $self->broker_class;

    my $broker = $self->broker_class->new($self->connect_options);
    $broker->connect;

    return $broker;
}

=head1 METHODS

=cut

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    
    return $class->$orig(
        connect_options => ref $_[0] eq 'HASH' ? $_[0] : { @_ }
    );
};

sub DEMOLISH {
    my $self = shift;
    
    $self->disconnect;
}

=head1 AUTHOR

Wolfgang Kinkeldei, E<lt>wolfgang@kinkeldei.deE<gt>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
1;
