function void = tag_slicer(filepath,tag,partition_names)
    fig = figure; clf(fig); hold on;
    ax = gca;
    for i = 1:3
        plot(tag.time,tag.mag(:,i));
    end
    xlabel("Time (seconds)")
    ylabel("Magnetometer Data")
    
    bounds = get_slicer_bounds(ax,length(partition_names));
    bounds = flip(bounds,1);

    for i = 1:length(partition_names)
        sliced_tag = slice(tag,bounds(i,:),partition_names(i));
        save(strcat(filepath,"\",partition_names{i}),'sliced_tag');
    end
end

function [bounds] = get_slicer_bounds(ax,num)
    while (true)
        % Draw two rectangles corresponding to beginning and ending sync
        % signals
        for i = 1:num
            drawrectangle(ax);
        end
    
        % Confirm the drawings (user still has time to adjust the rectangles
        % until confirming with `y + [ENTER]`
        in_str = input('Confirm the drawn rectangles (Y, [N]): ', "s");
    
        if strcmpi(in_str, "Y")
            break;
        else
            % Delete the rectangles and start again
            for i = 1:num
                rects = findobj(ax, 'Type', 'images.roi.Rectangle');
                for r = 1:length(rects)
                    delete(rects(r));
                end
            end
        end
    end
    
    bounds = NaN*zeros(num, 2);
    rects = findobj(ax, 'Type', 'images.roi.Rectangle');
    for i = 1:num
        bounds(i, 1:2) = [rects(i).Position(1), rects(i).Position(1)+rects(i).Position(3)];
        % sort to allow for rectangles to be input in any order
        bounds(i, :) = sort(bounds(i, :));
    end
end

