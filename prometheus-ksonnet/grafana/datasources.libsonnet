{
  local configMap = $.core.v1.configMap,

  /*
    to add datasources:

    grafanaDatasources+:: {
      'my-datasource.yml': $.grafana_datasource(name, url, default, method),
      'secure-datasource.yml': $.grafana_datasource_with_basicauth(name, url, username, password, default, method),
    },
  */
  grafanaDatasources+:: {},

  // Generates yaml string containing datasource config
  grafana_datasource(name, url, default=false, method='GET', type='prometheus'):: {
    name: name,
    type: type,
    access: 'proxy',
    url: url,
    isDefault: default,
    version: 1,
    editable: false,
    jsonData: {
      httpMethod: method,
    },
  },

  /*
    helper to allow adding datasources directly to the datasource_config_map
    eg:

    grafana_datasource_config_map+:
      $.grafana_add_datasource(name, url, default, method),
  */
  grafana_add_datasource(name, url, default=false, method='GET')::
    configMap.withDataMixin({
      ['%s.yml' % name]: $.util.manifestYaml({
        apiVersion: 1,
        datasources: [$.grafana_datasource(name, url, default, method)],
      }),
    }),

  // Generates yaml string containing datasource config
  grafana_datasource_with_basicauth(name, url, username, password, default=false, method='GET', type='prometheus'):: {
    name: name,
    type: type,
    access: 'proxy',
    url: url,
    isDefault: default,
    version: 1,
    editable: false,
    basicAuth: true,
    basicAuthUser: username,
    basicAuthPassword: password,
    jsonData: {
      httpMethod: method,
    },
  },

  /*
   helper to allow adding datasources directly to the datasource_config_map
   eg:

   grafana_datasource_config_map+:
     $.grafana_add_datasource_with_basicauth(name, url, username, password, default, method),
  */
  grafana_add_datasource_with_basicauth(name, url, username, password, default=false, method='GET')::
    configMap.withDataMixin({
      ['%s.yml' % name]: $.util.manifestYaml({
        apiVersion: 1,
        datasources: [$.grafana_datasource_with_basicauth(name, url, username, password, default, method)],
      }),
    }),

  grafana_datasource_config_map:
    configMap.new('grafana-datasources') +
    configMap.withDataMixin({
      [if std.endsWith(name, '.yml') then name else name + '.yml']: (
        if std.isString($.grafanaDatasources[name]) then
          $.grafanaDatasources[name]
        else
          $.util.manifestYaml({
            apiVersion: 1,
            datasources: [$.grafanaDatasources[name]],
          })
      )
      for name in std.objectFields($.grafanaDatasources)
    }) +
    configMap.metadata.withLabels($._config.grafana_datasource_labels),
}
