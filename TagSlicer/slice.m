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
        new_tag.gyro = new_tag.gryo(s:e,:);
    end
    
    if ~isempty(new_tag.temp)
        new_tag.temp = new_tag.temp(s:e);
    end

    if ~isempty(new_tag.mag)
        new_tag.mag = new_tag.mag(s:e,:);
    end

    if ~isempty(new_tag.rpy)
        new_tag.rpy = new_tag.mag(s:e,:);
    end

    if ~isempty(new_tag.head)
        new_tag.head = new_tag.head(s:e,:);
    end

    if ~isempty(new_tag.depth)
        new_tag.depth = new_tag.depth(s:e);
    end

    new_tag.name = name;
end

