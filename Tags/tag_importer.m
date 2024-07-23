% factory that calls the constructors for all the other tags
% NO SUPPORT FOR MTAG
function tag = tag_importer(filename,tag_type,tag_name)
    switch tag_type
        case 'D4'
            tag = D4(filename,tag_name);
            return;
        case 'D3'
            tag = D3(filename,tag_name);
            return;
        case 'dataLogger'
            tag = dataLogger(filename,tag_name);
            return;
        case 'uTag'
            tag = uTag(filename,tag_name);
            return;
        case 'sliced_tag'
            tag = standardTag(filename,tag_name);
            return;
        otherwise
            fprintf(tag_type + " is not a valid tag type\n");
            quit
    end
end

