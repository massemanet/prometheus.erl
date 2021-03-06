

# Module prometheus_registry #
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

<a name="types"></a>

## Data Types ##




### <a name="type-collect_callback">collect_callback()</a> ###


<pre><code>
collect_callback() = fun((<a href="#type-registry">registry()</a>, <a href="prometheus_collector.md#type-collector">prometheus_collector:collector()</a>) -&gt; any())
</code></pre>




### <a name="type-registry">registry()</a> ###


<pre><code>
registry() = atom()
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#clear-0">clear/0</a></td><td>Equivalent to <a href="#clear-1"><tt>clear(default)</tt></a>.</td></tr><tr><td valign="top"><a href="#clear-1">clear/1</a></td><td></td></tr><tr><td valign="top"><a href="#collect-2">collect/2</a></td><td></td></tr><tr><td valign="top"><a href="#collector_registeredp-2">collector_registeredp/2</a></td><td></td></tr><tr><td valign="top"><a href="#collectors-1">collectors/1</a></td><td></td></tr><tr><td valign="top"><a href="#deregister_collector-2">deregister_collector/2</a></td><td></td></tr><tr><td valign="top"><a href="#register_collector-2">register_collector/2</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="clear-0"></a>

### clear/0 ###

<pre><code>
clear() -&gt; ok
</code></pre>
<br />

Equivalent to [`clear(default)`](#clear-1).

<a name="clear-1"></a>

### clear/1 ###

<pre><code>
clear(Registry::<a href="prometheus_registry.md#type-registry">prometheus_registry:registry()</a>) -&gt; ok
</code></pre>
<br />

<a name="collect-2"></a>

### collect/2 ###

<pre><code>
collect(Registry, Callback) -&gt; ok
</code></pre>

<ul class="definitions"><li><code>Registry = <a href="prometheus_registry.md#type-registry">prometheus_registry:registry()</a></code></li><li><code>Callback = <a href="#type-collect_callback">collect_callback()</a></code></li></ul>

<a name="collector_registeredp-2"></a>

### collector_registeredp/2 ###

<pre><code>
collector_registeredp(Registry, Collector) -&gt; boolean()
</code></pre>

<ul class="definitions"><li><code>Registry = <a href="prometheus_registry.md#type-registry">prometheus_registry:registry()</a></code></li><li><code>Collector = <a href="prometheus_collector.md#type-collector">prometheus_collector:collector()</a></code></li></ul>

<a name="collectors-1"></a>

### collectors/1 ###

<pre><code>
collectors(Registry::<a href="prometheus_registry.md#type-registry">prometheus_registry:registry()</a>) -&gt; [Collector::<a href="prometheus_collector.md#type-collector">prometheus_collector:collector()</a>]
</code></pre>
<br />

<a name="deregister_collector-2"></a>

### deregister_collector/2 ###

<pre><code>
deregister_collector(Registry::<a href="prometheus_registry.md#type-registry">prometheus_registry:registry()</a>, Collector::<a href="prometheus_collector.md#type-collector">prometheus_collector:collector()</a>) -&gt; ok
</code></pre>
<br />

<a name="register_collector-2"></a>

### register_collector/2 ###

<pre><code>
register_collector(Registry::<a href="prometheus_registry.md#type-registry">prometheus_registry:registry()</a>, Collector::<a href="prometheus_collector.md#type-collector">prometheus_collector:collector()</a>) -&gt; ok
</code></pre>
<br />

