%agregar_ingreso_maximo_Clases

Clases = xlsread('Clases.xlsx');
%%
ndata=size(Clases,1); 
hogar_repetido=Clases(:,2);
[~, ind_1st_hogar, ~]=unique(hogar_repetido);
ind_1st_hogar_extra=[ind_1st_hogar; ndata+1];
personas_por_hogar=ind_1st_hogar_extra(2:end)-ind_1st_hogar_extra(1:end-1);

ingresoMax = zeros(ndata,1);
%%
hogar = 1;
persona = 1;
while persona <= ndata % corregir...
    disp(hogar)
    disp(persona)
    ind_hog = indices_hogar(hogar);
    ingresoMax(ind_hog:ind_hog+personas_por_hogar(hogar)-1) = max(Clases(ind_hog:ind_hog+personas_por_hogar(hogar)-1,9));
    persona = hogar + personas_por_hogar(hogar);
    hogar = hogar + 1;
end
%%
Clases2 = [Clases, ingresoMax];

xlswrite('Clases2.xlsx', Clases2, 'Hoja1', 'A1');  % to write new data into excel sheet.