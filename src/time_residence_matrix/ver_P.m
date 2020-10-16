function [] = ver_P(P, considerar_nvl_socioecono,...
    considerar_no_viajeros, restar_horas_sueno, modo_normalizacion, ...
    ambientes, nclases, nombres_clases, tomar_log, tpo_nvl_socio, quitar_cols)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Input:
    % - 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    title_image = 'Matriz';
    if tomar_log
        nombre = ' log_2(P)';
    else
        nombre = ' P';
    end
    if considerar_nvl_socioecono
        econo = strcat(', considerando nvl socioeconomico ', tpo_nvl_socio);
    else 
        econo = ', sin considerar nvls socioeconomicos';
    end
    
    if considerar_no_viajeros
        no_viaj = ', agregando personas sin viajes';
    else 
        no_viaj = ', sin considerar personas sin viajes';
    end
    
    if restar_horas_sueno
        sueno = ', quitando 7 horas de sueno al tiempo en el hogar';
    else 
        sueno = '';
    end
    
    title_image = strcat(title_image, nombre, econo, no_viaj, sueno, '.');
    
    econotipo = 'false';
    if considerar_nvl_socioecono
        econotipo = tpo_nvl_socio;
    end
    
    filename = strcat('images_matrix_P/P-', nombre,...
                    'econo', econotipo, num2str(considerar_nvl_socioecono), ...
                    '-no_viaj',num2str(considerar_no_viajeros),...
                    '-restarsueno',num2str(restar_horas_sueno),...
                    '-log',num2str(tomar_log),...
                    '-delcol',num2str(quitar_cols),...
                    '-norm',num2str(modo_normalizacion),'.png');
    
    figure('Position',[680 180 1041 918]);
    
    
    
    if tomar_log
        bar3(fliplr(log(P(:,quitar_cols+1:end)')/log(2)));
        %imagesc(log(P)/log(2))
    else
        bar3(fliplr(P(:,quitar_cols+1:end)'));
        %imagesc(P)
    end
    
    
    view(-60,50)
    ax=gca;
    ax.YTick=1:13-quitar_cols;
    ax.XTick=1:nclases;
    ax.YTickLabels=ambientes(quitar_cols+1:end);
    ax.XTickLabels=fliplr(nombres_clases);
    title(title_image)
    
    % guardar
    saveas(gcf,filename)
    
end