function index = find_index(signal, value)
    [~, index] = min(abs(signal - value));
end
