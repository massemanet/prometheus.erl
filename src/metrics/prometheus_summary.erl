-module(prometheus_summary).

%%% metric
-export([new/1,
         new/2,
         declare/1,
         declare/2,
         observe/2,
         observe/3,
         observe/4,
         dobserve/2,
         dobserve/3,
         dobserve/4,
         observe_duration/2,
         observe_duration/3,
         observe_duration/4,
         reset/1,
         reset/2,
         reset/3,
         value/1,
         value/2,
         value/3]).

%%% collector
-export([deregister_cleanup/1,
         collect_mf/2,
         collect_metrics/2]).

%%% gen_server
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3,
         start_link/0]).

-import(prometheus_model_helpers, [create_mf/5,
                                   label_pairs/1,
                                   gauge_metrics/1,
                                   gauge_metric/1,
                                   gauge_metric/2,
                                   counter_metric/1,
                                   counter_metric/2,
                                   summary_metric/3]).

-include("prometheus.hrl").

-behaviour(prometheus_metric).
-behaviour(prometheus_collector).
-behaviour(gen_server).

%%====================================================================
%% Macros
%%====================================================================

-define(TABLE, ?PROMETHEUS_SUMMARY_TABLE).
-define(SUM_POS, 3).
-define(COUNTER_POS, 2).

%%====================================================================
%% Metric API
%%====================================================================

new(Spec) ->
  new(Spec, default).

new(Spec, Registry) ->
  {Name, Labels, Help} = parse_summary_spec(Spec),
  prometheus_collector:register(?MODULE, Registry),
  prometheus_metric:insert_new_mf(?TABLE, Registry, Name, Labels, Help).

declare(Spec) ->
  declare(Spec, default).

declare(Spec, Registry) ->
  {Name, Labels, Help} = parse_summary_spec(Spec),
  prometheus_collector:register(?MODULE, Registry),
  prometheus_metric:insert_mf(?TABLE, Registry, Name, Labels, Help).

observe(Name, Value) ->
  observe(default, Name, [], Value).

observe(Name, LabelValues, Value) ->
  observe(default, Name, LabelValues, Value).

observe(Registry, Name, LabelValues, Value) when is_integer(Value) ->
  try
    ets:update_counter(?TABLE, {Registry, Name, LabelValues},
                       [{?COUNTER_POS, 1}, {?SUM_POS, Value}])
  catch error:badarg ->
      insert_metric(Registry, Name, LabelValues, Value, fun observe/4)
  end,
  ok;
observe(_Registry, _Name, _LabelValues, Value) ->
  erlang:error({invalid_value, Value, "observe accepts only integers"}).

dobserve(Name, Value) ->
  dobserve(default, Name, [], Value).

dobserve(Name, LabelValues, Value) ->
  dobserve(default, Name, LabelValues, Value).

dobserve(Registry, Name, LabelValues, Value) when is_number(Value) ->
  gen_server:cast(prometheus_summary,
                  {observe, {Registry, Name, LabelValues, Value}}),
  ok;
dobserve(_Registry, _Name, _LabelValues, Value) ->
  erlang:error({invalid_value, Value, "dobserve accepts only numbers"}).

observe_duration(Name, Fun) ->
  prometheus_misc:observe_duration(?MODULE, default, Name, [], Fun).

observe_duration(Name, LabelValues, Fun) ->
  prometheus_misc:observe_duration(?MODULE, default, Name, LabelValues, Fun).

observe_duration(Name, Registry, LabelValues, Fun) ->
  prometheus_misc:observe_duration(?MODULE, Registry, Name, LabelValues, Fun).

%% @equiv reset(default, Name, [])
reset(Name) ->
  reset(default, Name, []).

%% @equiv reset(default, Name, LabelValues)
reset(Name, LabelValues) ->
  reset(default, Name, LabelValues).

reset(Registry, Name, LabelValues) ->
  prometheus_metric:check_mf_exists(?TABLE, Registry, Name, LabelValues),
  ets:update_element(?TABLE, {Registry, Name, LabelValues},
                     [{?COUNTER_POS, 0}, {?SUM_POS, 0}]).

%% @equiv value(default, Name, [])
value(Name) ->
  value(default, Name, []).

%% @equiv value(default, Name, LabelValues)
value(Name, LabelValues) ->
  value(default, Name, LabelValues).

value(Registry, Name, LabelValues) ->
  [{_Key, Count, Sum}] = ets:lookup(?TABLE, {Registry, Name, LabelValues}),
  {Count, Sum}.

%%====================================================================
%% Collector API
%%====================================================================

deregister_cleanup(Registry) ->
  prometheus_metric:deregister_mf(?TABLE, Registry),
  true = ets:match_delete(?TABLE, {{Registry, '_', '_'}, '_', '_'}),
  ok.

collect_mf(Callback, Registry) ->
  [Callback(create_summary(Name, Help, {Labels, Registry})) ||
    [Name, Labels, Help, _] <- prometheus_metric:metrics(?TABLE, Registry)].

collect_metrics(Name, {Labels, Registry}) ->
  [summary_metric(lists:zip(Labels, LabelValues), Count, Sum) ||
    [LabelValues, Count, Sum] <- ets:match(?TABLE, {{Registry, Name, '$1'},
                                                    '$2', '$3'})].

%%====================================================================
%% Gen_server API
%%====================================================================

init(_Args) ->
  {ok, []}.

handle_call(_Call, _From, State) ->
  {noreply, State}.

handle_cast({observe, {Registry, Name, LabelValues, Value}}, State) ->
  dobserve_impl(Registry, Name, LabelValues, Value),
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

start_link() ->
  gen_server:start_link({local, prometheus_summary},
                        prometheus_summary, [], []).

%%====================================================================
%% Private Parts
%%====================================================================

parse_summary_spec(Spec) ->
  {Name, Labels, Help} = prometheus_metric:extract_common_params(Spec),
  validate_summary_labels(Labels),
  {Name, Labels, Help}.

validate_summary_labels(Labels) ->
  [raise_error_if_quantile_label_found(Label) || Label <- Labels].

raise_error_if_quantile_label_found("quantile") ->
  erlang:error({invalid_metric_label_name, "quantile",
                "summary cannot have a label named \"quantile\""});
raise_error_if_quantile_label_found(Label) ->
  Label.

dobserve_impl(Registry, Name, LabelValues, Value) ->
  case ets:lookup(?TABLE, {Registry, Name, LabelValues}) of
    [Metric] ->
      ets:update_element(?TABLE, {Registry, Name, LabelValues},
                         {?SUM_POS, sum(Metric) + Value}),
      ets:update_counter(?TABLE, {Registry, Name, LabelValues},
                         {?COUNTER_POS, 1});
    [] ->
      insert_metric(Registry, Name, LabelValues, Value, fun dobserve_impl/4)
  end.

insert_metric(Registry, Name, LabelValues, Value, ConflictCB) ->
  prometheus_metric:check_mf_exists(?TABLE, Registry, Name, LabelValues),
  case ets:insert_new(?TABLE, {{Registry, Name, LabelValues}, 1, Value}) of
    false -> %% some sneaky process already inserted
      ConflictCB(Registry, Name, LabelValues, Value);
    true ->
      ok
  end.

sum(Metric) ->
  element(?SUM_POS, Metric).

create_summary(Name, Help, Data) ->
  prometheus_model_helpers:create_mf(Name, Help, summary, ?MODULE, Data).
