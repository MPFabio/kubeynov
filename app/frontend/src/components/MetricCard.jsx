const MetricCard = ({ title, value, icon, color, trend }) => {
  const colorClasses = {
    blue: 'bg-blue-500',
    green: 'bg-green-500',
    purple: 'bg-purple-500',
    orange: 'bg-orange-500',
  }

  const trendIcon = trend > 0 ? '↑' : trend < 0 ? '↓' : '→'
  const trendColor = trend > 0 ? 'text-red-400' : trend < 0 ? 'text-green-400' : 'text-gray-400'

  return (
    <div className="bg-gray-800 rounded-lg shadow-xl p-6 border border-gray-700 hover:border-gray-600 transition-all">
      <div className="flex items-center justify-between mb-4">
        <div className={`${colorClasses[color]} w-12 h-12 rounded-lg flex items-center justify-center text-2xl`}>
          {icon}
        </div>
        {trend !== undefined && (
          <span className={`text-sm font-semibold ${trendColor}`}>
            {trendIcon} {Math.abs(trend).toFixed(1)}%
          </span>
        )}
      </div>
      <h3 className="text-gray-400 text-sm font-medium mb-2">{title}</h3>
      <p className="text-white text-3xl font-bold">{value}</p>
    </div>
  )
}

export default MetricCard


