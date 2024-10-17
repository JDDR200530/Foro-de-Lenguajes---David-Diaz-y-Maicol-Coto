# Clase Jugador
package Jugador;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = {
        nombre    => $args{nombre} || 'Jugador',
        dinero    => $args{dinero} || 1000,
        acciones  => {},
    };
    bless $self, $class;
    return $self;
}

sub mostrar_estado {
    my $self = shift;
    print "\nEstado de $self->{nombre}:\n";
    print "Dinero: $self->{dinero}\n";
    print "Acciones: ";
    foreach my $empresa (keys %{$self->{acciones}}) {
        print "$empresa: $self->{acciones}{$empresa} acciones\n";
    }
    print "\n";
}

sub comprar_acciones {
    my ($self, $empresa, $precio, $cantidad) = @_;
    my $total_costo = $precio * $cantidad;
    if ($self->{dinero} >= $total_costo) {
        $self->{dinero} -= $total_costo;
        $self->{acciones}{$empresa} += $cantidad;
        print "$self->{nombre} ha comprado $cantidad acciones de $empresa por $total_costo.\n";
    } else {
        print "$self->{nombre} no tiene suficiente dinero para comprar $cantidad acciones de $empresa.\n";
    }
}

sub vender_acciones {
    my ($self, $empresa, $precio, $cantidad) = @_;
    
    
    if (exists $self->{acciones}{$empresa} && $self->{acciones}{$empresa} >= $cantidad) {
        $self->{acciones}{$empresa} -= $cantidad;
        my $total_venta = $precio * $cantidad;
        $self->{dinero} += $total_venta;
        print "$self->{nombre} ha vendido $cantidad acciones de $empresa por $total_venta.\n";
    } else {
        print "$self->{nombre} no tiene suficientes acciones de $empresa para vender.\n";
    }
}

sub en_bancarrota {
    my $self = shift;
    return $self->{dinero} <= 0;
}

# Clase Empresa
package Empresa;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = {
        nombre => $args{nombre},
        valor_accion  => $args{valor_accion},
    };
    bless $self, $class;
    return $self;
}

sub ajustar_valor_accion {
    my ($self, $cambio) = @_;
    $self->{valor_accion} += $cambio;
    $self->{valor_accion} = 1 if $self->{valor_accion} < 1;  # El valor mínimo es 1
}

# Clase JuegoEconomico
package JuegoEconomico;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = {
        jugadores => $args{jugadores},
        empresas  => $args{empresas},
        turnos    => $args{turnos} || 15,  # Ajustamos los turnos a 15
        turno_actual => 0,  # Contador de turnos
        empresa_misteriosa => undef,  # Se añadirá más adelante
    };
    bless $self, $class;
    return $self;
}

sub iniciar {
    my $self = shift;
    print "Bienvenido al simulador economico de compra y venta de acciones\n";
    
    for my $turno (1..$self->{turnos}) {
        $self->{turno_actual} = $turno;  # Actualizamos el contador de turnos
        print "\n===== Turno $turno =====\n";
        
        foreach my $jugador (@{$self->{jugadores}}) {
            print "\nTurno de $jugador->{nombre}:\n";
            $jugador->mostrar_estado();

            # Elegir una empresa para comprar/vender acciones
            my $empresa = $self->elegir_empresa();
            print "Empresa seleccionada: $empresa->{nombre}\n";
            print "Valor actual de la accion: $empresa->{valor_accion}\n";
            
            # El jugador decide cuantas acciones comprar
            print "Cuantas acciones de $empresa->{nombre} quieres comprar?: ";
            my $cantidad_comprar = <STDIN>;
            chomp $cantidad_comprar;
            $jugador->comprar_acciones($empresa->{nombre}, $empresa->{valor_accion}, $cantidad_comprar);
            
            # El jugador decide cuantas acciones vender
            print "Cuantas acciones de $empresa->{nombre} quieres vender?: ";
            my $cantidad_vender = <STDIN>;
            chomp $cantidad_vender;
            $jugador->vender_acciones($empresa->{nombre}, $empresa->{valor_accion}, $cantidad_vender);

            if ($self->{turno_actual} >= 3 && $self->{turno_actual} <= 15) { 
                if (int(rand(2)) == 1) { 
                    $self->preguntar_misteriosa($jugador);
                }
            }

            # Limpiar la consola al terminar el turno
            $self->limpiar_consola();

            if ($jugador->en_bancarrota()) {
                print "$jugador->{nombre} ha quedado en bancarrota. Fin del juego\n";
                return;
            }
        }

        my $evento = $self->evento_aleatorio();
        $self->aplicar_evento($evento);
    }
    
    print "\nEl juego ha terminado. Estos son los resultados finales:\n";
    foreach my $jugador (@{$self->{jugadores}}) {
        $jugador->mostrar_estado();
    }
}

sub elegir_empresa {
    my $self = shift;
    return $self->{empresas}[int(rand(scalar @{$self->{empresas}}))];
}

sub evento_aleatorio {
    my $self = shift;
    my @eventos = (
        'caida_bolsa',
        'subida_bolsa',
    );
    return $eventos[int(rand(@eventos))];
}

sub aplicar_evento {
    my ($self, $evento) = @_;
    if ($evento eq 'caida_bolsa') {
        foreach my $empresa (@{$self->{empresas}}) {
            $empresa->ajustar_valor_accion(-1);
            print "Caida de la bolsa. El nuevo valor de las acciones de $empresa->{nombre} es $empresa->{valor_accion}\n";
        }
    } elsif ($evento eq 'subida_bolsa') {
        foreach my $empresa (@{$self->{empresas}}) {
            $empresa->ajustar_valor_accion(1);
            print "Subida de la bolsa. El nuevo valor de las acciones de $empresa->{nombre} es $empresa->{valor_accion}\n";
        }
    }
}


sub preguntar_misteriosa {
    my ($self, $jugador) = @_;
    print "Quieres comprar acciones de una compania misteriosa? (si/no): ";
    my $respuesta = <STDIN>;
    chomp $respuesta;
    
    if ($respuesta eq 'si') {
        if (int(rand(2)) == 0) {
            $self->{empresa_misteriosa} = Empresa->new(nombre => 'Compania Misteriosa', valor_accion => 10);
            $jugador->comprar_acciones('Compania Misteriosa', 0, 100);
            print "$jugador->{nombre} ha recibido 100 acciones de la Compania Misteriosa gratis!\n";
        } else {
            
            $jugador->{dinero} -= 100;
            print "$jugador->{nombre} ha perdido $100 en la inversion misteriosa.\n";
        }
    } else {
        print "Has decidido no invertir en la compania misteriosa.\n";
    }
}

sub limpiar_consola {
    if ($^O eq 'MSWin32') {
        system("cls");  
    } else {
        system("clear");  
    }
}

# Ejecutar el juego
my $jugador1 = Jugador->new(nombre => 'Carlos');
my $jugador2 = Jugador->new(nombre => 'Lucia');

# Crear más empresas
my $empresa1 = Empresa->new(nombre => 'TechCorp', valor_accion => 50);
my $empresa2 = Empresa->new(nombre => 'FoodInc', valor_accion => 30);
my $empresa3 = Empresa->new(nombre => 'AutoMotive', valor_accion => 40);
my $empresa4 = Empresa->new(nombre => 'PharmaCorp', valor_accion => 70);
my $empresa5 = Empresa->new(nombre => 'EnergyPlus', valor_accion => 20);
my $empresa6 = Empresa->new(nombre => 'RetailWorld', valor_accion => 35);
my $empresa7 = Empresa->new(nombre => 'GreenTech', valor_accion => 45);
my $empresa8 = Empresa->new(nombre => 'FinBank', valor_accion => 55);

# Agregar las empresas al juego
my $juego = JuegoEconomico->new(
    jugadores => [$jugador1, $jugador2],
    empresas  => [$empresa1, $empresa2, $empresa3, $empresa4, $empresa5, $empresa6, $empresa7, $empresa8],
);

$juego->iniciar();