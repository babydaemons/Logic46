using System.Collections.Concurrent;

internal class PositionDao
{
    private ConcurrentQueue<Position> _positions = new ();
    public PositionDao()
    {
    }

    internal bool GetPosition(out Position position)
    {
        return _positions.TryDequeue(out position);
    }

    internal void InsertPosition(Position position)
    {
        _positions.Enqueue(position);
    }
}