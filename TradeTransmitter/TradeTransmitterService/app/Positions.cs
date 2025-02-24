using System.Text.Json;

public struct Position
{
    public int change;
    public int command;
    public string symbol;
    public double lots;
    public string position_id;
}

public class Positions
{
    private Dictionary<string, List<Position>>? positions = null;
    private string json_path;

    public Positions(string json_path)
    {
        this.json_path = json_path;
        Load();
    }

    public void AddPosition(string email, uint account, Position position)
    {
        string key = $"{email}:{account}";
        lock(positions)
        {
            if (positions == null)
            {
                positions = new Dictionary<string, List<Position>>();
            }
            if (positions.ContainsKey(key))
            {
                positions[key].Add(position);
            }
            else
            {
                positions.Add(key, new List<Position> { position });
            }
        }
        Save();
    }

    public List<Position> GetPosition(string email, uint account)
    {
        string key = $"{email}:{account}";
        if (positions != null && positions.ContainsKey(key) && positions[key].Count == 0)
        {
            return new List<Position>();
        }
        if (positions == null)
        {
            positions = [];
            Save();
            return [];
        }
        if (!positions.ContainsKey(key))
        {
            positions.Add(key, []);
            Save();
            return [];
        }
        var result = new List<Position>(positions[key]);
        positions[key].Clear();
        Save();
        return result;
    }

    private void Load()
    {
        if (File.Exists(json_path))
        {
            string json = File.ReadAllText(json_path);
            positions = JsonSerializer.Deserialize<Dictionary<string, List<Position>>>(json);
        }
        else
        {
            positions = [];
            Save();
        }
    }

    private void Save()
    {
        string json = JsonSerializer.Serialize(positions);
        File.WriteAllText(json_path, json);
    }
}
