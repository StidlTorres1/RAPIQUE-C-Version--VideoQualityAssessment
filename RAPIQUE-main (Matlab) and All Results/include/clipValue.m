function val = clipValue(val, valMin, valMax)
% Comienza a contar el tiempo
ti = cputime;

for i = 1 : 1 : size(val(:))
	if val(i) < valMin
		val(i) = valMin;
	elseif val(i) > valMax
		val(i) = valMax;
	end
end

% Detener el contador de tiempo
elapsed_time = cputime - ti;
upd_FuncInfo("clipValue",elapsed_time);