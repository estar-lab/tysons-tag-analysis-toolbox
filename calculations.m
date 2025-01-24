syms scale offset
[sol_scale, sol_offset] = solve(0.314342*scale+offset/10 == -690.5910736, 0.019928*scale+offset/10 == 0);
sol_scale = vpa(sol_scale)
sol_offset = vpa(sol_offset)
