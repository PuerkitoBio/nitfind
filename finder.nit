# Finder exports the types required to find patterns
# in some files.
module finder

import matcher
import file_resolver
import reporter

# Finder class puts it all together, finds matchers in the files
# and sends them to the reporter.
class Finder
    # matcher to use to find hits in the files.
    var matcher: Matcher
    # resolver that identifies the files to search.
    var resolver: FileResolver
    # reporter to use to report hits.
    var reporter: Reporter

    private var before_lines = 0
    private var after_lines = 0
    private var max_line_length = 200

    # find is the method that runs the search.
    fun find: Int do
        var files = resolver.files
        for file in files do
            var reader = file.to_path.open_ro

            # skip binary files
            var bytes = reader.peek(512)
            if bytes.has(0) then
                reader.close
                continue
            end

            var hits = new Array[Hit]
            var line_no = 0
            var buf = new CircularBuffer(before_lines + after_lines + 1)
            for line in reader.each_line do
                line_no += 1
                buf.add(line.substring(0, max_line_length))
                if matcher.match(line) then
                    hits.add(new Hit(line_no, line_no, buf))
                    # TODO : handle before/after contextual lines, grow buffer as needed
                    buf = new CircularBuffer(before_lines + after_lines + 1)
                end
            end
            reader.close

            if hits.length > 0 then reporter.report(file, hits)
        end
        return 0
    end
end
