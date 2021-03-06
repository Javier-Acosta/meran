#!/usr/bin/perl
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
use strict;
require Exporter;
use CGI;
use C4::AR::Auth;
my $input=new CGI;
my ($template, $session, $t_params)= get_template_and_user({
								template_name => "informacion/error.tmpl",
								query => $input,
								type => "opac",
								authnotrequired => 1,
								flagsrequired => {  ui => 'ANY', 
                                                    tipo_documento => 'ANY', 
                                                    accion => 'CONSULTA', 
                                                    entorno => 'undefined'},
			     });
my $session                 = CGI::Session->load();
my $message_error           = "404";
if ($ENV{'REDIRECT_STATUS'}  eq "404") {
    $message_error = C4::AR::Preferencias::getValorPreferencia('404_error_message') || $message_error;
} elsif ($ENV{'REDIRECT_STATUS'}  eq "500") {
    $message_error = C4::AR::Preferencias::getValorPreferencia('500_error_message') || $message_error;
}  
$t_params->{'message_error'}        = $message_error;
C4::AR::Auth::output_html_with_http_headers($template, $t_params, $session);