using System.Collections.Concurrent;

internal class PositionDao
{
    private ConcurrentDictionary<string, ConcurrentQueue<Position>> _positions = new ConcurrentDictionary<string, ConcurrentQueue<Position>>();
    public PositionDao()
    {
    }

    internal List<Position> GetPositions(string email)
    {
        return _positions.GetOrAdd(email, new ConcurrentQueue<Position>()).ToList();
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