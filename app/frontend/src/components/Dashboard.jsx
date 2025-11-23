import { LineChart, Line, AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import MetricCard from './MetricCard'

const Dashboard = ({ metrics }) => {
  const chartData = metrics.history?.map((item, index) => ({
    time: new Date(item.timestamp).toLocaleTimeString(),
    cpu: item.cpu,
    memory: item.memory,
    requests: item.requests,
    latency: item.latency
  })) || []

  const currentMetrics = metrics.current || {}

  return (
    <div className="space-y-6">
      {/* Metric Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard
          title="CPU Usage"
          value={`${currentMetrics.cpu || 0}%`}
          icon="⚡"
          color="blue"
          trend={metrics.trends?.cpu}
        />
        <MetricCard
          title="Memory Usage"
          value={`${currentMetrics.memory || 0}%`}
          icon="💾"
          color="green"
          trend={metrics.trends?.memory}
        />
        <MetricCard
          title="Requests/sec"
          value={currentMetrics.requests || 0}
          icon="📊"
          color="purple"
          trend={metrics.trends?.requests}
        />
        <MetricCard
          title="Latency"
          value={`${currentMetrics.latency || 0}ms`}
          icon="⏱️"
          color="orange"
          trend={metrics.trends?.latency}
        />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* CPU & Memory Chart */}
        <div className="bg-gray-800 rounded-lg shadow-xl p-6 border border-gray-700">
          <h2 className="text-xl font-semibold text-white mb-4">CPU & Memory</h2>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={chartData}>
              <defs>
                <linearGradient id="colorCpu" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.8}/>
                  <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                </linearGradient>
                <linearGradient id="colorMemory" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#10b981" stopOpacity={0.8}/>
                  <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
              <XAxis dataKey="time" stroke="#9ca3af" />
              <YAxis stroke="#9ca3af" />
              <Tooltip 
                contentStyle={{ backgroundColor: '#1f2937', border: '1px solid #374151', borderRadius: '8px' }}
                labelStyle={{ color: '#f3f4f6' }}
              />
              <Legend />
              <Area type="monotone" dataKey="cpu" stroke="#3b82f6" fillOpacity={1} fill="url(#colorCpu)" name="CPU %" />
              <Area type="monotone" dataKey="memory" stroke="#10b981" fillOpacity={1} fill="url(#colorMemory)" name="Memory %" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Requests Chart */}
        <div className="bg-gray-800 rounded-lg shadow-xl p-6 border border-gray-700">
          <h2 className="text-xl font-semibold text-white mb-4">Requêtes par seconde</h2>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
              <XAxis dataKey="time" stroke="#9ca3af" />
              <YAxis stroke="#9ca3af" />
              <Tooltip 
                contentStyle={{ backgroundColor: '#1f2937', border: '1px solid #374151', borderRadius: '8px' }}
                labelStyle={{ color: '#f3f4f6' }}
              />
              <Legend />
              <Bar dataKey="requests" fill="#8b5cf6" name="Requests/sec" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Latency Chart */}
        <div className="bg-gray-800 rounded-lg shadow-xl p-6 border border-gray-700 lg:col-span-2">
          <h2 className="text-xl font-semibold text-white mb-4">Latence (ms)</h2>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
              <XAxis dataKey="time" stroke="#9ca3af" />
              <YAxis stroke="#9ca3af" />
              <Tooltip 
                contentStyle={{ backgroundColor: '#1f2937', border: '1px solid #374151', borderRadius: '8px' }}
                labelStyle={{ color: '#f3f4f6' }}
              />
              <Legend />
              <Line type="monotone" dataKey="latency" stroke="#f97316" strokeWidth={2} dot={{ fill: '#f97316' }} name="Latency (ms)" />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* System Info */}
      <div className="bg-gray-800 rounded-lg shadow-xl p-6 border border-gray-700">
        <h2 className="text-xl font-semibold text-white mb-4">Informations système</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-gray-700 rounded-lg p-4">
            <p className="text-gray-400 text-sm">Uptime</p>
            <p className="text-white text-2xl font-bold">{metrics.system?.uptime || 'N/A'}</p>
          </div>
          <div className="bg-gray-700 rounded-lg p-4">
            <p className="text-gray-400 text-sm">Total Requests</p>
            <p className="text-white text-2xl font-bold">{metrics.system?.totalRequests || 0}</p>
          </div>
          <div className="bg-gray-700 rounded-lg p-4">
            <p className="text-gray-400 text-sm">Version</p>
            <p className="text-white text-2xl font-bold">{metrics.system?.version || '1.0.0'}</p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Dashboard

