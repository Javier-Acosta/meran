# Meran - MERAN UNLP is a ILS (Integrated Library System) wich provides Catalog,
# Circulation and User's Management. It's written in Perl, and uses Apache2
# Web-Server, MySQL database and Sphinx 2 indexing.
# Copyright (C) 2009-2015 Grupo de desarrollo de Meran CeSPI-UNLP
# <desarrollo@cespi.unlp.edu.ar>
#
# This file is part of Meran.
#
# Meran is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Meran is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Meran.  If not, see <http://www.gnu.org/licenses/>.
package C4::AR::XLSGenerator;
use strict;
use C4::AR::Auth;
use C4::AR::Filtros;
use Encode;
use Spreadsheet::WriteExcel::Simple;
my $input = new CGI;
my $authnotrequired= 0;
use vars qw(@EXPORT @ISA);
@ISA=qw(Exporter);
@EXPORT=qw(  
    &exportarMejorPresupuesto;
    &exportarPesupuesto;
    &exportarReporteCircGeneral;
);
=item
    Devuelve la planilla xls con los datos pasados por parametro
=cut
sub getXLS{
    my ($tabla_a_exportar, $headers_tabla, $headers_planilla, $campos_hidden, $nombre_proveedor)    = @_;
    my $msg_object                                                                                  = C4::AR::Mensajes::create();
    my $spread_sheet                                                                                = Spreadsheet::WriteExcel::Simple->new;
    
    # headers planilla
    $spread_sheet->write_bold_row($headers_planilla); 
    
    # campo hidden, id_proveedor FIXME no lo oculta
    $spread_sheet->write_bold_row($campos_hidden);   
    
    # headers tabla
    $spread_sheet->write_bold_row($headers_tabla); 
    
    #tabla
    foreach my $celda (@$tabla_a_exportar){
        $spread_sheet->write_row($celda);       
    }
    my $data;
  
    $data = $spread_sheet->data; 
    return ($data);
}
sub exportarMejorPresupuesto{
     my ($tabla_a_exportar, $headers_tabla) = @_;
     my $msg_object= C4::AR::Mensajes::create();
     
     my $ss = Spreadsheet::WriteExcel::Simple->new;
     $ss->write_bold_row($headers_tabla);   
     
     foreach my $celda (@$tabla_a_exportar){
        $ss->write_row($celda);       
     }
     eval{
          $ss->save("/usr/share/meran/intranet/htdocs/intranet-tmpl/reports/mejor_presupuesto.xls"); 
     };
     if ($@){
           $msg_object->{'error'}= 1;
           C4::AR::Mensajes::add($msg_object, {'codMsg'=> 'A037', 'params' => []} ) ;  
     } else {
           $msg_object->{'error'}= 0;
           C4::AR::Mensajes::add($msg_object, {'codMsg'=> 'A036', 'params' => []} ) ;  
    }
    return ($msg_object);
}
sub xlsHeader{
    my ($filename) = @_;
    $filename = $filename || "report_export.xls";
    my $session = CGI::Session->load();
    my $header =
      $session->header( -type => 'application/excel', -attachment => $filename );
    return ($header);
}
sub exportarReporteReservasCirculacion{
     my ($rep_historial_circulacion) = @_;     
     my @headers_tabla= (
                decode('utf8', C4::AR::Filtros::i18n("Responsable")),
                decode('utf8', C4::AR::Filtros::i18n("Título")),
                decode('utf8', C4::AR::Filtros::i18n("Autor")),
                decode('utf8', C4::AR::Filtros::i18n("Código de barras")),
                decode('utf8', C4::AR::Filtros::i18n("Signatura Topográfica")),
                decode('utf8', C4::AR::Filtros::i18n("Usuario")),
                decode('utf8', C4::AR::Filtros::i18n("Fecha")),
                decode('utf8', C4::AR::Filtros::i18n("Operación"))
        );
     my $ss = Spreadsheet::WriteExcel::Simple->new;
     $ss->write_bold_row(\@headers_tabla);   
     
     foreach my $historial_circulacion (@$rep_historial_circulacion){
        my @fila_tabla = ();
        my $responsable="";
        if($historial_circulacion->getResponsable() eq "Sistema") {
            $responsable="SISTEMA";
        }elsif($historial_circulacion->responsable_ref->persona){
            $responsable=$historial_circulacion->responsable_ref->persona->getApeYNom();
        }else{
            $responsable = C4::AR::Filtros::i18n("Material inexistente");
        }
        $fila_tabla[0] = decode('utf8', $responsable);
        if($historial_circulacion->nivel2->nivel1) {
            $fila_tabla[1] = decode('utf8', $historial_circulacion->nivel2->nivel1->getTituloStringEscaped());
            $fila_tabla[2] = decode('utf8', $historial_circulacion->nivel2->nivel1->getAutorStringEscaped());
        }
        else{
            $fila_tabla[1] =  C4::AR::Filtros::i18n("Material inexistente");
            $fila_tabla[2] =  C4::AR::Filtros::i18n("Material inexistente");
        }
        eval {
            if($historial_circulacion->getId3 && $historial_circulacion->nivel3) {
                $fila_tabla[3] =  $historial_circulacion->nivel3->getBarcode();
                $fila_tabla[4] =  $historial_circulacion->nivel3->getSignatura();
            }
            else{
                $fila_tabla[3] =  C4::AR::Filtros::i18n("Reserva de grupo");
                $fila_tabla[4] =  $historial_circulacion->nivel2->getPrimerSignatura();
            }
        };
        if ($@){
            $fila_tabla[3] =  C4::AR::Filtros::i18n("Reserva de grupo");
            $fila_tabla[4] =  $historial_circulacion->nivel2->getPrimerSignatura();
        }
        $fila_tabla[5] = decode('utf8', $historial_circulacion->socio->getNro_socio());
        $fila_tabla[6] = $historial_circulacion->getFecha_formateada();
        $fila_tabla[7] = $historial_circulacion->getTipo_operacion();
        $ss->write_row(\@fila_tabla);       
     }
        print $ss->data(); 
}
sub exportarReporteCirculacionGeneral{
     my ($rep_historial_circulacion_general) = @_;
    
     my @headers_tabla= (
                decode('utf8', C4::AR::Filtros::i18n("Cantidad de Renovaciones")),
                decode('utf8', C4::AR::Filtros::i18n("Cantidad de Usuarios")),
                decode('utf8', C4::AR::Filtros::i18n("Cantidad de Devoluciones")),
        );
     my $ss = Spreadsheet::WriteExcel::Simple->new;
     $ss->write_bold_row(\@headers_tabla);   
     my @fila_tabla = ();
     $fila_tabla[0] = $rep_historial_circulacion_general->{'cantidad_renovaciones'};
     $fila_tabla[1] = $rep_historial_circulacion_general->{'cantidad_usuarios'};
     $fila_tabla[2] = $rep_historial_circulacion_general->{'cantidad_devoluciones'};
     $ss->write_row(\@fila_tabla);
    
    print $ss->data(); 
}
sub exportarReporteCirculacionPrestamosVencidos{
     my ($prestamos_vencidos) = @_;     
     my @headers_tabla= (
                decode('utf8', C4::AR::Filtros::i18n("Apellido y nombre")),
                decode('utf8', C4::AR::Filtros::i18n("Número de Socio")),
                decode('utf8', C4::AR::Filtros::i18n("Ejemplar")),
                decode('utf8', C4::AR::Filtros::i18n("Tipo de préstamo")),
                decode('utf8', C4::AR::Filtros::i18n("Fecha de préstamo")),
                decode('utf8', C4::AR::Filtros::i18n("Fecha de vencimiento")),
        );
     my $ss = Spreadsheet::WriteExcel::Simple->new;
     $ss->write_bold_row(\@headers_tabla);   
     
     foreach my $prestamo_vencido (@$prestamos_vencidos){
        my @fila_tabla = ();
        eval {
            $fila_tabla[0] =  decode('utf8', $prestamo_vencido->socio->persona->getApeYNom());
        };
        if ($@){
            $fila_tabla[0] =  C4::AR::Filtros::i18n("Usuario inexistente");
        }
        $fila_tabla[1] =  $prestamo_vencido->getNro_socio;
        $fila_tabla[2] =  $prestamo_vencido->nivel3->codigo_barra;
        $fila_tabla[3] =  decode('utf8', $prestamo_vencido->tipo->getDescripcion);
        $fila_tabla[4] =  $prestamo_vencido->getFecha_prestamo_formateada;
        $fila_tabla[5] =  $prestamo_vencido->getFecha_vencimiento_reporte_formateada;
        $ss->write_row(\@fila_tabla);       
     }
        print $ss->data(); 
}
sub exportarReporteColecciones {
     my ($ejemplares) = @_;
     my @headers_tabla= (
                decode('utf8', C4::AR::Filtros::i18n("Título")),
                decode('utf8', C4::AR::Filtros::i18n("Autor")),
                decode('utf8', C4::AR::Filtros::i18n("Edición")),
                decode('utf8', C4::AR::Filtros::i18n("Código")),
                decode('utf8', C4::AR::Filtros::i18n("Signatura Topográfica")),
                decode('utf8', C4::AR::Filtros::i18n("Fecha de alta")),
                decode('utf8', C4::AR::Filtros::i18n("Operador")),
        );
     my $ss = Spreadsheet::WriteExcel::Simple->new;
     $ss->write_bold_row(\@headers_tabla);   
     
     foreach my $ejemplar (@$ejemplares){
        my @fila_tabla = ();
        $fila_tabla[0] =  decode('utf8', $ejemplar->nivel1->getTituloStringEscaped());
        $fila_tabla[1] =  decode('utf8', $ejemplar->nivel1->getAutorStringEscaped());
        $fila_tabla[2] =  decode('utf8', $ejemplar->nivel2->getEdicion());
        if ($ejemplar->nivel2->getAnio_publicacion()){
            if($fila_tabla[2]){
                $fila_tabla[2] .= " ";
            }
            $fila_tabla[2] .= "(".decode('utf8', $ejemplar->nivel2->getAnio_publicacion()).")";
        }
        $fila_tabla[3] =  $ejemplar->getBarcode();
        $fila_tabla[4] =  $ejemplar->getSignatura();
        $fila_tabla[5] =  $ejemplar->getCreatedAt_format();
        $fila_tabla[6] =  decode('utf8', $ejemplar->getCreatedByToString());
        $ss->write_row(\@fila_tabla);       
     }
        print $ss->data(); 
}
sub exportarReporteDisponibilidad {
     my ($ejemplares) = @_;
     my @headers_tabla= (
                decode('utf8', C4::AR::Filtros::i18n("Título")),
                decode('utf8', C4::AR::Filtros::i18n("Autor")),
                decode('utf8', C4::AR::Filtros::i18n("Signatura Topográfica")),
                decode('utf8', C4::AR::Filtros::i18n("Código")),
                decode('utf8', C4::AR::Filtros::i18n("Edición")),
                decode('utf8', C4::AR::Filtros::i18n("Fecha Cambio de disponibilidad")),
                decode('utf8', C4::AR::Filtros::i18n("Estado")),
        );
     my $ss = Spreadsheet::WriteExcel::Simple->new;
     $ss->write_bold_row(\@headers_tabla);   
     
     foreach my $ejemplar (@$ejemplares){
        my @fila_tabla = ();
        $fila_tabla[0] =  decode('utf8', $ejemplar->nivel1->getTituloStringEscaped());
        $fila_tabla[1] =  decode('utf8', $ejemplar->nivel1->getAutorStringEscaped());
        $fila_tabla[2] =  $ejemplar->getSignatura();
        $fila_tabla[3] =  $ejemplar->getBarcode();
        $fila_tabla[4] =  decode('utf8', $ejemplar->nivel2->getEdicion());        
        $fila_tabla[5] =  $ejemplar->getFechaUltimoCambioDisp();
        $fila_tabla[6] =  decode('utf8', $ejemplar->getEstado());
        $ss->write_row(\@fila_tabla);       
     }
        print $ss->data(); 
}
sub exportarReporteBusquedas{
     my ($busquedas) = @_;
     my @headers_tabla= (
                decode('utf8', C4::AR::Filtros::i18n("Valor")),
                decode('utf8', C4::AR::Filtros::i18n("Campo")),
                decode('utf8', C4::AR::Filtros::i18n("Intra/Opac")),
                decode('utf8', C4::AR::Filtros::i18n("Usuario")),
                decode('utf8', C4::AR::Filtros::i18n("Fecha")),
        ); 
     my $ss = Spreadsheet::WriteExcel::Simple->new;
     $ss->write_bold_row(\@headers_tabla);   
     
     foreach my $busqueda (@$busquedas){
        my @fila_tabla = ();
        $fila_tabla[0] =  decode('utf8', $busqueda->valor);
        $fila_tabla[1] =  decode('utf8', $busqueda->campo);
        $fila_tabla[2] =  decode('utf8', $busqueda->tipo);
        eval {
            $fila_tabla[3] =  decode('utf8', $busqueda->busqueda->socio->persona->getApeYNom());
        };
        if ($@){
            $fila_tabla[3] =  C4::AR::Filtros::i18n("Usuario inexistente");
        }
        $fila_tabla[4] = $busqueda->busqueda->getFecha_formateada();        
        $ss->write_row(\@fila_tabla);       
     }
        print $ss->data(); 
}
sub exportarReporteUsuarios{
     my ($usuarios) = @_;
     my @headers_tabla= (
                decode('utf8', C4::AR::Filtros::i18n("Apellido y Nombre")),
                decode('utf8', C4::AR::Filtros::i18n("Tarjeta de Id")),
                decode('utf8', C4::AR::Filtros::i18n("Legajo")),
                decode('utf8', C4::AR::Filtros::i18n("Fecha último acceso")),
                decode('utf8', C4::AR::Filtros::i18n("F. Activación")),
                decode('utf8', C4::AR::Filtros::i18n("Fecha alta")),
                decode('utf8', C4::AR::Filtros::i18n("Categoria")),
                decode('utf8', C4::AR::Filtros::i18n("Regularidad"))
        ); 
     my $ss = Spreadsheet::WriteExcel::Simple->new;
     $ss->write_bold_row(\@headers_tabla);   
     
     foreach my $socio (@$usuarios){
        my @fila_tabla = ();
        $fila_tabla[0] =  decode('utf8', $socio->persona->getApeYNom());
        $fila_tabla[1] =  decode('utf8', $socio->getNro_socio);
        $fila_tabla[2] =  decode('utf8', $socio->persona->legajo);
        if($socio->getLastLoginAll){
            $fila_tabla[3] =  decode('utf8', $socio->getLastLoginAllFormatted);
        }else{
            $fila_tabla[3] =  C4::AR::Filtros::i18n("--------");
        }
        $fila_tabla[4] = $socio->getFecha_alta();        
        $fila_tabla[5] = $socio->persona->getFecha_alta();   
        $fila_tabla[6] = $socio->categoria->getDescription(); 
        $fila_tabla[7] = $socio->esRegularToString();
        $ss->write_row(\@fila_tabla);       
     }
        print $ss->data(); 
}
END { }       # module clean-up code here (global destructor)
1;
__END__    
