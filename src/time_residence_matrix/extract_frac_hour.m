function frac_hora = extract_frac_hour(string_hora)
% EXTRACT_FRAC_HOUR Transforma un string que representa una hora a una
% fraccion del dia. 
%   *Argumentos:*
%   * |string_hora|: en formato |yyyy-MM-dd HH:mm:ss|. 
%    
%   *Ejemplo:*
%   |'1899-12-30 21:20:10'| --> |'21:20:10'| --> 21.3361 hrs --> 21.3361/24
%   = 0.8890
%   >> frac_hora = extract_frac_hour('1899-12-30 21:20:10')
%   frac_hora =
%       0.8890
% 
%   Ver tambien HOURS, DURATION.
if isnan(string_hora)
    frac_hora = nan;
else
    frac_hora = hours(duration(string_hora(end-7:end)))/24;
end