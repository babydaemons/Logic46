using System.Collections.Concurrent;

internal class PositionDao
{
    private ConcurrentDictionary<string, ConcurrentQueue<Position>> _positions = new ConcurrentDictionary<string, ConcurrentQueue<Position>>();
    public PositionDao()
    {
    }

    internal bool GetPosition(string name, out Position position)
    {
        return _positions.GetOrAdd(name, new ConcurrentQueue<Position>()).TryDequeue(out position);
    }

    internal void InsertPosition(Position position)
    {
        _positions.GetOrAdd(position.name, new ConcurrentQueue<Position>()).Enqueue(position);
    }

    internal bool ExistPosition(string name, int ticket)
    {
       return _positions.GetOrAdd(name, new ConcurrentQueue<Position>()).Any(position => position.ticket == ticket);
    }
}