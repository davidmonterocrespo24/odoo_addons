<%!
    import datetime
%>


<%def name="render_float(f)">
<%
    if type(f) != type(0.0):
        f = float(f)
    if int(f) == f:
        f = int(f)
    return f
%>
</%def>


<%def name="render_resources(line)">
    <%
        read_only = line.get('read_only', False)
    %>
    <td class="resource">
        <%
            resources = line.get('resources', [])
        %>
        <span class="name">${resources[-1]['label']}</span>
        %if editable and not read_only:
            %for res in resources:
                <%
                    res_id = res['id']
                    res_label = res['label']
                    res_value = res['value']
                    res_field_id = "%s_res_%s_%s" % (name, line['id'], res_id)
                %>
                <input type="hidden" id="${res_field_id}" name="${res_field_id}" value="${res_value}" title="${res_label}"/>
            %endfor
        %endif
    </td>
</%def>


<%def name="render_float_line(line, date_range, level=1)">
    <%
        read_only = line.get('read_only', False)
    %>
    <tr class="level level_${level}
        %if line['id'] == 'template':
            template
        %endif
        %if read_only:
            read_only
        %endif
        "
        %if not read_only:
            id="${'%s_line_%s' % (name, line['id'])}"
        %endif
        >
        ${render_resources(line)}
        <td class="delete_line">
            %if editable and not read_only and not line.get('required', False):
                <span class="button delete_row">X</span>
            %endif
        </td>
        %for date in date_range:
            <td class="float">
                <%
                    cell_id = '%s_cell_%s_%s' % (name, line['id'], date)
                    cell_value = line.get('cells_data', {}).get(date, None)
                %>
                %if cell_value is not None:
                    %if editable and not read_only:
                        <input type="text" kind="float" name="${cell_id}" id="${cell_id}" value="${render_float(cell_value)}" size="1" class="${line['widget']}"/>
                    %else:
                        <span kind="float" value="${render_float(cell_value)}"
                            %if not editable and cell_value <= 0.0:
                                class="zero"
                            %endif
                            %if not read_only:
                                id="${cell_id}"
                            %endif
                            >
                                ${render_float(cell_value)}
                        </span>
                    %endif
                %endif
            </td>
        %endfor
        <%
            row_total = sum([v for (k, v) in line.get('cells_data', dict()).items()])
        %>
        <td class="total
            %if not editable and row_total <= 0.0:
                zero
            %endif
            "
            %if not read_only:
                id="${name}_row_total_${line['id']}"
            %endif
            >
            ${render_float(row_total)}
        </td>
        %for line_property_value in [line.get(c['line_property'], 0.0) for c in value['additional_columns'] if 'line_property' in c]:
            <td
                %if not editable and line_property_value <= 0.0:
                    class="zero"
                %endif
            >
                ${render_float(line_property_value)}
            </td>
        %endfor
    </tr>
</%def>


<%def name="render_resource_selector(res_def)">
    <%
        res_id = res_def.get('id', None)
        res_values = res_def.get('values', [])
        selector_id = "%s_res_list_%s" % (name, res_id)
    %>
    %if len(res_values) and editable:
        <span class="resource_values">
            <select id="${selector_id}" kind="char" name="${selector_id}" type2="" operator="=" class="selection_search selection">
                <option value="default" selected="selected">&mdash; Select here new line's resource &mdash;</option>
                %for (res_value, res_label) in res_values:
                    <option value="${res_value}">${res_label}</option>
                %endfor
            </select>
            <span class="button add_row">+</span>
        </span>
    %endif
</%def>


<%def name="render_sub_matrix_header(level_res, res_values, level, date_range, sub_lines=[], css_class=None)">
    <%
        # Build a virtual line to freeze resources at that level
        virtual_line = {
            'id': 'dummy%s' % value['row_uid'],
            'resources': level_res,
            }
        value['row_uid'] += 1
    %>
    <tr id="${'%s_line_%s' % (name, virtual_line['id'])}" class="resource_line level level_${level}
        %if css_class:
            ${css_class}
        %endif
        ">
        ${render_resources(virtual_line)}
        <td colspan="${len(date_range) + 1}" class="resource_selector">
            ${render_resource_selector(res_values)}
        </td>
        <%
            row_total = []
            for line in sub_lines:
                row_total += [v for (k, v) in line.get('cells_data', dict()).items()]
            row_total = sum(row_total)
        %>
        <td id="${name}_row_total_${virtual_line['id']}" class="total
            %if not editable and row_total <= 0.0:
                zero
            %endif
            ">
            ${render_float(row_total)}
        </td>
        %for line_property in [c['line_property'] for c in value['additional_columns'] if 'line_property' in c]:
            <%
                additional_sum = sum([line.get(line_property, 0.0) for line in sub_lines])
            %>
            <td
                %if not editable and additional_sum <= 0.0:
                    class="zero"
                %endif
            >
                ${render_float(additional_sum)}
            </td>
        %endfor
    </tr>
</%def>


<%def name="render_sub_matrix(lines, resource_value_list, date_range, level=1, level_resources=[])">
    %if level < len(resource_value_list):
        <%
            res_def = resource_value_list[level - 1]
            res_id = res_def.get('id', None)
            res_values = res_def.get('values', [])
        %>
        %for (res_value, res_label) in res_values:
            <%
                level_res = level_resources + [{
                    'id': res_id,
                    'label': res_label,
                    'value': res_value,
                    }]
                sub_lines = []
                for line in lines:
                    matching_resources = [r for r in line.get('resources') if r['id'] == res_id and r['value'] == res_value]
                    if len(matching_resources):
                        sub_lines.append(line)
            %>
            %if len(sub_lines):
                ${render_sub_matrix_header(level_res, resource_value_list[level], level, date_range, sub_lines)}
                ${render_sub_matrix(sub_lines, resource_value_list, date_range, level + 1, level_res)}
            %endif
        %endfor
    %endif
    %if level == len(resource_value_list):
        %for line in lines:
            ${render_float_line(line, date_range, level)}
        %endfor
    %endif
</%def>


<%
    css_classes = ''
    if value is not None:
        css_classes = ' '.join(value.get('class', []))
%>


<div id="${name}" class="matrix ${css_classes}">

    %if type(value) == type({}) and 'date_range' in value:

        <%
            # Initialize our global new row UID
            value['row_uid'] = 1

            # Extract some basic information
            lines = value.get('matrix_data', [])
            top_lines = [l for l in lines if l.get('position', 'body') == 'top']
            bottom_lines = [l for l in lines if l.get('position', 'body') == 'bottom']
            body_lines = [l for l in lines if l.get('position', 'body') not in ['top', 'bottom']]
            resource_value_list = value.get('resource_value_list', [])
            date_range = value['date_range']
            column_date_label_format = value.get('column_date_label_format', '%Y-%m-%d')
        %>

        <style type="text/css">
            /* Reset OpenERP default styles */
            .matrix table tfoot td {
                font-weight: normal;
            }

            .matrix table th {
                text-transform: none;
                border-bottom: 0;
            }

            .item .matrix input,
            .item .matrix select {
                width: inherit;
                min-width: inherit;
            }

            div.non-editable .matrix table td {
                border: 0;
            }


            /* Set our style */

            .matrix .toolbar {
                margin-bottom: 1em;
            }

            .matrix select {
                width: 30em;
            }

            .matrix .zero {
                color: #ccc;
            }

            .matrix .template {
                display: none;
            }

            .matrix .total,
            .matrix .total td,
            .matrix th {
                font-weight: bold;
                background-color: #ddd;
            }

            .matrix td.warning {
                background: #f00;
                color: #fff;
            }

            .matrix table {
                text-align: center;
                margin-top: 1em;
                margin-bottom: 1em;
            }

            .matrix input {
                text-align: center;
            }

            .matrix table .resource,
            .matrix table .resource_selector {
                text-align: left;
            }

            .matrix table .button.delete_row,
            .matrix table .button.increment {
                display: block;
                padding: .3em;
            }

            .matrix td, div.non-editable .matrix table td,
            .matrix th, div.non-editable .matrix table th {
                height: 2em;
                min-width: 2em;
                margin: 0;
                padding: 0 .1em;
                border-top: 1px solid #ccc;
            }

            %for i in range(1, len(resource_value_list)):
                .matrix tbody tr.level_${i} td, div.non-editable .matrix table tbody tr.level_${i} td {
                    border-top-width: ${len(resource_value_list) - i + 1}px;
                }
                .matrix .level_${i+1} td.resource,
                .matrix .level_${i+1} td.resource_selector,
                .matrix .level_${i+1} td.delete_line {
                    padding-left: ${i}em;
                }
            %endfor
        </style>

        %if editable:
            <div class="toolbar level level_0">
                ${render_resource_selector(resource_value_list[0])}
                <span id="matrix_button_template" class="button increment template">
                    Button template
                </span>
            </div>
        %endif

        <table>
            <thead>
                <tr>
                    <th class="resource">${value['title']}</th>
                    <th></th>
                    %for date in date_range:
                        <th>${datetime.datetime.strptime(date, '%Y%m%d').strftime(column_date_label_format)}</th>
                    %endfor
                    <th class="total">Total</th>
                    %for (i, c) in enumerate(value['additional_columns']):
                        <th>${c.get('label', "Additional column %s" % i)}</th>
                    %endfor
                </tr>
            </thead>
            <tfoot>
                <tr class="total">
                    <td class="resource">Total</td>
                    <td></td>
                    %for date in date_range:
                        <%
                            column_values = [line['cells_data'][date] for line in body_lines if date in line['cells_data']]
                        %>
                        %if len(column_values):
                            <%
                                column_total = sum(column_values)
                            %>
                            <td id="${name}_column_total_${date}" class="
                                %if not editable and column_total <= 0.0:
                                    zero
                                %endif
                                %if column_total > 1:
                                    warning
                                %endif
                                ">
                                ${render_float(column_total)}
                        %else:
                            <td>
                        %endif
                        </td>
                    %endfor
                    <%
                        grand_total = sum([sum([v for (k, v) in line['cells_data'].items()]) for line in body_lines])
                    %>
                    <td id="${name}_grand_total"
                        %if not editable and grand_total <= 0.0:
                            class="zero"
                        %endif
                        >
                        ${render_float(grand_total)}
                    </td>
                    %for line_property in [c['line_property'] for c in value['additional_columns'] if 'line_property' in c]:
                        <%
                            additional_sum = sum([line.get(line_property, 0.0) for line in body_lines])
                        %>
                        <td class="total
                            %if not editable and additional_sum <= 0.0:
                                zero
                            %endif
                        ">
                            ${render_float(additional_sum)}
                        </td>
                    %endfor
                </tr>

                %for line in [l for l in bottom_lines if l['widget'] != "boolean"]:
                    ${render_float_line(line, date_range)}
                %endfor

                %for line in [l for l in bottom_lines if l['widget'] == "boolean"]:
                    <!-- TODO: merge with render_float_line() -->
                    <tr id="${'%s_line_%s' % (name, line['id'])}" class="boolean_line">
                        ${render_resources(line)}
                        <td></td>
                        %for date in date_range:
                            <td class="boolean">
                                <%
                                    cell_id = '%s_cell_%s_%s' % (name, line['id'], date)
                                    cell_value = line['cells_data'].get(date, None)
                                %>
                                %if cell_value is not None:
                                    %if editable:
                                        <input type="hidden" kind="boolean" name="${cell_id}" id="${cell_id}" value="${cell_value and '1' or '0'}"/>
                                        <input type="checkbox" enabled="enabled" kind="boolean" class="checkbox" id="${cell_id}_checkbox_"
                                            %if cell_value:
                                                checked="checked"
                                            %endif
                                        />
                                    %else:
                                        <input type="checkbox" name="${cell_id}" id="${cell_id}" kind="boolean" class="checkbox" readonly="readonly" disabled="disabled" value="${cell_value and '1' or '0'}"
                                            %if cell_value:
                                                checked="checked"
                                            %endif
                                        />
                                    %endif
                                %endif
                            </td>
                        %endfor
                        <%
                            row_total = sum([v for (k, v) in line.get('cells_data', dict()).items()])
                        %>
                        <td class="total"
                            id="${name}_row_total_${line['id']}"
                            %if not editable and row_total <= 0.0:
                                class="zero"
                            %endif
                            >
                            ${render_float(row_total)}
                        </td>
                        %for line_property_value in [line.get(c['line_property'], 0.0) for c in value['additional_columns'] if 'line_property' in c]:
                            <td
                                %if not editable and line_property_value <= 0.0:
                                    class="zero"
                                %endif
                            >
                                ${render_float(line_property_value)}
                            </td>
                        %endfor
                    </tr>
                %endfor

            </tfoot>
            <tbody>
                <%
                    template_line = [l for l in lines if l['id'] == 'template'][0]
                    non_templates_lines = [l for l in body_lines if l['id'] != 'template']
                %>
                ${render_sub_matrix(non_templates_lines, resource_value_list, date_range)}

                <%doc>
                    Render a sub-matrix header template for each level of resource.
                    Level 0 is skipped as it's already rendered outside of the matrix table.
                </%doc>
                <%
                    level_res = []
                %>
                %for (res_index, res_def) in enumerate(resource_value_list):
                    %if res_index != 0:
                        ${render_sub_matrix_header(level_res, res_def, res_index, date_range, css_class='template')}
                    %endif
                    <%
                        res_id = res_def.get('id', None)
                        level_res.append({
                            'id': res_id,
                            'label': '%s template label' % res_id,
                            'value': 0,
                            })
                    %>
                %endfor

                <%doc>
                    Render a template float line to help the interactive Javascript code render consistent stuff.
                </%doc>
                ${render_float_line(template_line, date_range, level=len(resource_value_list))}
            </tbody>
        </table>

    %else:

        Can't render the matrix widget, unless a period is selected.

    %endif

</div>