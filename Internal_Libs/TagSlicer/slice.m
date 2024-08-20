function new_tag = slice(tag,bounds,name)
    s = find_index(tag.time,bounds(1));
    e = find_index(tag.time,bounds(2));

    new_tag = tag;

    new_tag.time = new_tag.time(s:e);
    new_tag.time = new_tag.time - new_tag.time(1);

    if ~isempty(new_tag.accel)
        new_tag.accel = new_tag.accel(s:e,:);
    end

    if ~isempty(new_tag.gyro)
        new_tag.gyro = new_tag.gyro(s:e,:);
    end
    
    if ~isempty(new_tag.temp_imu)
        new_tag.temp_imu = new_tag.temp_imu(s:e);
    end

    if ~isempty(new_tag.temp_pres)
        new_tag.temp_pres = new_tag.temp_pres(s:e);
    end

    if ~isempty(new_tag.mag)
        new_tag.mag = new_tag.mag(s:e,:);
    end

    if ~isempty(new_tag.rpy_tag)
        new_tag.rpy_tag = new_tag.rpy_tag(s:e,:);
    end

    if ~isempty(new_tag.rpy_whale)
        new_tag.rpy_whale = new_tag.rpy_whale(s:e,:);
    end

    if ~isempty(new_tag.depth)
        new_tag.depth = new_tag.depth(s:e);
    end

    new_tag.name = name;
end

