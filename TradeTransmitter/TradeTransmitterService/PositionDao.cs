using System.Collections.Concurrent;

internal class PositionDao
{
    private ConcurrentDictionary<string, ConcurrentQueue<Position>> _positions = new ConcurrentDictionary<string, ConcurrentQueue<Position>>();
    public PositionDao()
    {
    }

    internal bool GetPositions(string email, out Position position)
    {
        return _positions.GetOrAdd(email, new ConcurrentQueue<Position>()).TryDequeue(out position);
    }

    internal void InsertPosition(Position position)
    {
        _positions.GetOrAdd(position.email, new ConcurrentQueue<Position>()).Enqueue(position);
    }

    internal bool ExistPosition(string email, string position_id)
    {
       return _positions.GetOrAdd(email, new ConcurrentQueue<Position>()).Any(position => position.position_id == position_id);
    }
}