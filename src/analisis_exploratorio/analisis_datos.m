%% Construccion arreglo viajes circular por persona
%
% cabeza del arreglo (8):
% id_viaje edad sexo ocupacion tramo_ingreso tipo_dia temporada n_viajes
% y luego para cada viaje (10):
% proposito modo hora_inicio hora_fin zona_origen zona_destino
% comuna_origen comuna_destino manhattan xo yo xd yd ambiente_inicio ambiente_fin
%
% * Los primeros 6 digitos de id_viaje es id_hogar
% * Los primeros 8 digitos de id_viaje es id_persona
% * sexo: 1 hombre 2 mujer
% * proposito: 1,2 trabajo, 3,4 estudio, 5 salud, 6,8 visitar/llevar alguien,
% 7 volver a casa, 9,10,11 comer/buscar algo/de compras, 12 tramites,
% 13 recreacion, 14 otros
% * ambiente: 0 hogar, 1 trabajo, 2 compras, 3 escuela/liceo/universidad
% 4 visitar/llevar alguien, 5 tramites, 6 recreacion, 7 salud, 8 otros
%
% Ejemplo:
% cabeza del arreglo: 1734620101 33 2 5 3 1 1 4
% viaje 1: 1 1 07:20 08:50 94 94 398 398 0 1
% viaje 2: 1 7 18:00 19:50 94 94 398 398 1 0
% viaje 3: 1 11 20:30 21:05 94 94 398 398 0 2
% viaje 4: 1 7 22:00 22:30 94 94 398 398 2 0

% sqlite3
% 
% .open databaseEOD2012.db
% .headers on
% .mode csv
% .output data.csv
% SELECT
% Viaje.Viaje as id_viaje, Edad as edad, Sexo as sexo, Persona.Ocupacion as ocupacion,
% Persona.TramoIngresoFinal as ingreso, Hogar.TipoDia as tipo_dia,
% Hogar.Temporada as temporada, Persona.Viajes as viajes,
% Viaje.Proposito as proposito, Viaje.ModoAgregado as modo,
% Viaje.HoraIni as hora_inicio, Viaje.HoraFin as hora_fin,
% Viaje.ZonaOrigen as zona_origen, Viaje.ZonaDestino as zona_destino, 
% Viaje.ComunaOrigen as comuna_origen, Viaje.ComunaDestino as comuna_destino,
% DistanciaViaje.DistManhattan as manhattan,
% Viaje.OrigenCoordX as xo, Viaje.OrigenCoordY as yo,
% Viaje.DestinoCoordX as xd, Viaje.DestinoCoordY as yd
% FROM
% Persona, Viaje, EdadPersonas, Hogar, DistanciaViaje
% WHERE
% Viaje.Persona=Persona.Persona and Viaje.Persona=EdadPersonas.Persona
% and Viaje.Hogar=Hogar.Hogar and Viaje.Viaje=DistanciaViaje.Viaje;
% .quit
%Data=xlsread('./EOD2012/DatosStgoEOD2012.xlsx');
%%
%save Data
%%
load Data
%% Propositos
proposito=Data(:,9);
proposito_categorias={'trabajo','trabajo',...
    'estudios','estudios','salud','visitar','volver a casa',...
    'b/d alguien','comer/tomar algo','b/d algo','compras',...
    'tramites','recreo','otros'};
C=categorical(proposito,1:14,proposito_categorias);
%figure(1)
%H=histogram(C,'Normalization','probability');
proposito_categorias2={'trabajo','trabajo','compras','compras','compras',...
    'estudios','estudios','visitar/llevar alguien',...
    'visitar/llevar alguien',...
    'tramites','recreo','salud','otros','volver a casa'};
C2=categorical(proposito,[1 2 9 10 11 3 4 6 8 12 13 5 14 7],...
    proposito_categorias2);
figure('Position',[301 137 1454 733]);
H=histogram(C2,'Normalization','probability');
title('Frecuencia de prop?sitos de viajes')
ylabel('fracci?n')
%% origen-destino
xo=Data(:,18);
yo=Data(:,19);
xd=Data(:,20);
yd=Data(:,21);
for k=1:100:length(xo)
    if xo(k)>3.3*1e5 && xd(k)>3.3*1e5
        line([xo(k) xd(k)],[yo(k) yd(k)])
    end
end
axis equal
%% tiempo viaje
tiempo_viaje=24*60*(Data(:,12)-Data(:,11));
C3=discretize(tiempo_viaje,[0 3 7 15 30 60 120 4000],'categorical',...
    {'[0-3min]','[3-7min]','[7-15min]','[15-30min]','[30-60min]','[1hr-2hr]','[2hr y mas]'});
figure('Position',[301 137 1454 733]);
histogram(C3,'Normalization','probability')
title('Duraci?n de los viajes')
ylabel('fracci?n')
%% Hora inicio y fin del viaje
hora_inicio=Data(:,11);
indices_trabajo = find(proposito==1 | proposito==2);
indices_estudios = find(proposito==3 | proposito==4);
indices_compras = find(proposito==9 | proposito==10 | proposito==11);
hora_fin=Data(:,12);
nhoras=48;
switch nhoras
    case 24,
        cat_horas={'0-1','1-2','2-3','3-4','4-5','5-6','6-7','7-8',...
            '8-9','9-10','10-11','11-12','12-13','13-14','14-15','15-16',...
            '16-17','17-18','18-19','19-20','20-21','21-22','22-23','23-24'};
     case 48,
        cat_horas={'00:00-00:30','00:30-01:00','01:00-01:30','01:30-02:00',...
            '02:00-02:30','02:30-03:00','03:00-03:30','03:30-04:00',...
            '04:00-04:30','04:30-05:00','05:00-05:30','05:30-06:00',...
            '06:00-06:30','06:30-07:00','07:00-07:30','07:30-08:00',...
            '08:00-08:30','08:30-09:00','09:00-09:30','09:30-10:00',...
            '10:00-10:30','10:30-11:00','11:00-11:30','11:30-12:00',...
            '12:00-12:30','12:30-13:00','13:00-13:30','13:30-14:00',...
            '14:00-14:30','14:30-15:00','15:00-15:30','15:30-16:00',...
            '16:00-16:30','16:30-17:00','17:00-17:30','17:30-18:00',...
            '18:00-18:30','18:30-19:00','19:00-19:30','19:30-20:00',...
            '20:00-20:30','20:30-21:00','21:00-21:30','21:30-22:00',...
            '22:00-22:30','22:30-23:00','23:00-23:30','23:30-24:00'...
            };
end
C41=discretize(hora_inicio(indices_trabajo),0:1/nhoras:1,'categorical',cat_horas);
C42=discretize(hora_inicio(indices_estudios),0:1/nhoras:1,'categorical',cat_horas);
C43=discretize(hora_inicio(indices_compras),0:1/nhoras:1,'categorical',cat_horas);
indices_regreso = find(proposito==7);
C5=discretize(hora_fin(indices_regreso),0:1/nhoras:1,'categorical',cat_horas);
figure('Position',[301 137 1454 733]);
hold on
title('Hora inicio de viajes')
histogram(C5,'BarWidth',0.9)
histogram(C41,'BarWidth',0.8)
histogram(C42,'BarWidth',0.6)
histogram(C43,'BarWidth',0.4)
hold off
title('Distribuci?n de viajes de ida y regreso por hora')
legend('regreso casa','ida trabajo','ida estudios','ida compras')
%% Edad y sexo
id_viaje=Data(:,1);
persona=floor(id_viaje/100);
[p indices_personas]=unique(persona);
edad=Data(indices_personas,2);
sexo=Data(indices_personas,3);
subplot(1,2,1)
histogram(edad)
title('Edad')
xlabel('a?os')
subplot(1,2,2)
histogram(sexo)
title('Sexo')
xlabel('Hombre, Mujer')
%% Distancia viajes
d_Manhattan=Data(:,17);
d_Manhattan(d_Manhattan>5*1e4 | d_Manhattan<0)=[];
histogram(d_Manhattan/1000);
title('Distancia de viajes')
xlabel('km')
%% Zonas viajes
zona_origen=Data(:,13);
zona_destino=Data(:,14);
plot(zona_origen,zona_destino,'.','MarkerSize',1)
xlabel('zona origen')
ylabel('zona destino')
%% Comunas viajes
comuna_origen=Data(:,15);
comuna_destino=Data(:,16);
plot(comuna_origen,comuna_destino,'.','MarkerSize',1)
xlabel('comuna origen')
ylabel('comuna destino')

%% Tiempos de residencia (en fraccion del dia)
ndata=size(Data,1);
ncolumnas=size(Data,2);
tiempo_residencia=zeros(ndata,4);
% campo 1: ambiente, campo 2: tpo_residencia, 
% campo 3: ambiente de viaje, campo 4: tiempo de viaje
i=1;
while i<=ndata
    nviajes=Data(i,8);
    proposito_inicial=Data(i,9);
    modo=Data(i,10);
    hora_inicio=Data(i,11);
    hora_fin=Data(i,12);
    if nviajes==1
        if proposito_inicial==7 % regreso a casa
            tiempo_residencia(i,1)=0; % hogar
            tiempo_residencia(i,2)=1-hora_fin; % tpo hogar desde la hora de regreso hasta 24:00        
        else
            tiempo_residencia(i,1)=0; % hogar
            tiempo_residencia(i,2)=hora_inicio; % tpo hogar de 0:00 hasta la hora de partida        
        end
        tiempo_residencia(i,3)=modo; % modo de transporte        
        tiempo_residencia(i,4)=hora_fin-hora_inicio; % tpo de viaje        
    else
        hora_fin_ultimo_viaje=Data(i+nviajes-1,12);
        tiempo_residencia(i,1)=0; % se asume viajes parten y llegan al final al hogar
        tiempo_residencia(i,2)=hora_inicio; % tpo hogar de las 0:00 hasta la hora de partida del primer viaje        
        tiempo_residencia(i,2)=tiempo_residencia(i,2)+1-hora_fin_ultimo_viaje; % tpo hogar del ultimo viaje hasta las 24:00        
        tiempo_residencia(i,3)=modo; % modo de transporte primer viaje        
        tiempo_residencia(i,4)=hora_fin-hora_inicio; % tpo de primer viaje        
        for j=2:nviajes
            proposito_anterior=Data(i+j-2,9);
            proposito_actual=Data(i+j-1,9);
            modo_actual=Data(i+j-1,10);
            hora_inicio_actual=Data(i+j-1,11);
            hora_fin_actual=Data(i+j-1,12);
            hora_inicio_anterior=Data(i+j-2,11);
            hora_fin_anterior=Data(i+j-2,12);
            switch proposito_anterior
                case 7,
                tiempo_residencia(i+j-1,1)=0; % hogar
                if hora_inicio_actual>=hora_fin_anterior
                    tiempo_residencia(i+j-1,2)=hora_inicio_actual-hora_fin_anterior; % tpo en hogar
                else
                    % el tiempo inicio_actual pas? las 0:00
                    tiempo_residencia(i+j-1,2)=hora_inicio_actual+1-hora_fin_anterior; % tpo en hogar
                end
                otherwise,
                tiempo_residencia(i+j-1,1)=proposito_anterior; % modo
                tiempo_residencia(i+j-1,2)=hora_inicio_actual-hora_fin_anterior; % tpo proposito anterior            
            end
            tiempo_residencia(i+j-1,3)=modo_actual; % modo de transporte        
            tiempo_residencia(i+j-1,4)=hora_fin_actual-hora_inicio_actual; % tpo de viaje        
        end
    end
    i=i+nviajes;
end
%%
indices_hogar=find(tiempo_residencia(:,1)==0);
indices_trabajo=find(tiempo_residencia(:,1)==1 | tiempo_residencia(:,1)==2);
indices_estudio=find(tiempo_residencia(:,1)==3 | tiempo_residencia(:,1)==4);
indices_compras=find(tiempo_residencia(:,1)==11);
%hold on
figure('Position',[680 84 1118 1014])
subplot(4,1,1)
histogram(tiempo_residencia(indices_hogar,2))
title('fracci?n de tiempo diario de residencia en hogar')
xlim([0 1])
subplot(4,1,2)
histogram(tiempo_residencia(indices_trabajo,2))
title('fracci?n de tiempo diario de residencia en trabajo')
xlim([0 1])
subplot(4,1,3)
histogram(tiempo_residencia(indices_estudio,2))
title('fracci?n de tiempo diario de residencia en estudio')
xlim([0 1])
subplot(4,1,4)
histogram(tiempo_residencia(indices_compras,2))
title('fracci?n de tiempo diario de residencia en compras')
xlim([0 1])
%hold off
%%
%cat_fraccion={'0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1.0'};
p1=tiempo_residencia(indices_trabajo,2);
p2=tiempo_residencia(indices_estudio,2);
p3=tiempo_residencia(indices_compras,2);
p4=tiempo_residencia(indices_hogar,2);
p1=p1(p1>0 & p1<=1)*24;
p2=p2(p2>0 & p2<=1)*24;
p3=p3(p3>0 & p3<=1)*24;
p4=p4(p4>0 & p4<=1)*24;
C1=discretize(p1,24*(0:0.05:1),'categorical');
C2=discretize(p2,24*(0:0.05:1),'categorical');
C3=discretize(p3,24*(0:0.05:1),'categorical');
C4=discretize(p4,24*(0:0.05:1),'categorical');
figure('Position',[74 220 1791 731]);
hold on
histogram(C4,'BarWidth',0.9)
histogram(C1,'BarWidth',0.8)
histogram(C2,'BarWidth',0.6)
histogram(C3,'BarWidth',0.4)
title('fracci?n de periodos de tiempo diario de residencia (horas)')
%xlim([0 1])
legend('hogar','trabajo','estudios','compras')
hold off

%% Calculos
tpo_hogar=sum(p4,'omitnan')
tpo_trabajo=sum(p1,'omitnan')
tpo_estudio=sum(p2,'omitnan')
tpo_compras=sum(p3,'omitnan')
suma=tpo_hogar+tpo_trabajo+tpo_estudio+tpo_compras;
h=bar([tpo_hogar tpo_trabajo tpo_estudio tpo_compras]/suma);
title('1: hogar 2: trabajo 3: estudios 4: compras')

%% Mas calculos
for i=1:18
   indice_modo{i}=find(tiempo_residencia(:,3)==i);
end
hold on
for i=1:4
    histogram(tiempo_residencia(indice_modo{i},4)*24)
end
hold off
xlim([0 2])