import Control.Monad
import Data.Char
import Data.List
import qualified Data.Map as Map
import System.Directory
import System.Environment
import System.Exit
import System.IO


main = do
    args <- getArgs
    case args of
        ["trim",   "-in", infn, "-hash", hash, "-out", outfn] -> trim_cmd infn hash outfn
        ["untrim", "-in", infn, "-hash", hash, "-out", outfn] -> untrim_cmd infn hash outfn
        otherwise                                             -> usage


usage = mapM_ putStrLn ["usage (v0.1.0):  indel {trim | untrim} -in inFile -hash hashFile -out outFile"]
exit  = exitWith ExitSuccess
err   = exitWith (ExitFailure 1)


not_found :: String -> IO ()
not_found fn = do 
    fn_exists <- doesFileExist fn
    when (not fn_exists) (hPutStr stderr (fn ++ " not found\n") >> err)


not_overwriting :: String -> IO ()
not_overwriting fn = do 
    fn_exists <- doesFileExist fn
    when fn_exists (hPutStr stderr (fn ++ " exists, will not overwrite\n") >> err)   


ext :: String -> String
ext = reverse . takeWhile (/= '.') . reverse


trim_cmd :: String -> String -> String -> IO ()
trim_cmd infn hash outfn = do
    mapM_ not_found [infn]
    mapM_ not_overwriting [hash, outfn]
    file <- readFile infn
    mapM_ (trim hash (ext infn) outfn) (lines file)


trim :: String -> String -> String -> String -> IO ()
trim hash "vcf" outfn str@('#' : xs) = appendFile outfn $ str ++ "\n"
trim hash "vcf" outfn str            = let (chr : pos : id : ref : alt : xs) = words str
                                           (fst_base, snd_base, rebased) = rebase ref alt
                                       in do 
                                           when rebased (appendFile hash $ (intercalate "\t" $ [chr, pos, ref, alt]) ++ "\n")
                                           appendFile outfn $ (intercalate "\t" $ [chr, pos, id, fst_base, snd_base] ++ xs) ++ "\n"
trim hash "bim" outfn str            = let (chr : id : x : pos : a0 : a1 : _) = words str
                                           (fst_base, snd_base, rebased) = rebase a0 a1
                                       in do
                                           when rebased (appendFile hash $ (intercalate "\t" $ [chr, pos, a0, a1]) ++ "\n")
                                           appendFile outfn $ (intercalate "\t" $ [chr, id, x, pos, fst_base, snd_base]) ++ "\n"


rebase :: String -> String -> (String, String, Bool)
rebase xs ys 
  | all isLetter $ xs ++ ys = rebase0 xs ys
  | otherwise               = default_rebase


rebase0 :: String -> String -> (String, String, Bool)
rebase0 [x] [y]     = ([x], [y], False)
rebase0 [x] (y:_)   = ([x], [remap x], True)
rebase0 (x:_) [y]   = ([remap y], [y],True)
rebase0 (x:_) (y:_) = default_rebase


default_rebase :: (String, String, Bool)
default_rebase = ("G", "A", True)


remap :: Char -> Char
remap 'A' = 'C'
remap 'C' = 'T'
remap 'T' = 'G'
remap 'G' = 'A'
remap ch  = ch


untrim_cmd :: String -> String -> String -> IO ()
untrim_cmd infn hash outfn = do
    mapM_ not_found [infn, hash]
    mapM_ not_overwriting [outfn]  
    hash_file <- readFile hash
    let hash_map = Map.fromList $ map make_hash (lines hash_file)
    file <- readFile infn 
    mapM_ (untrim hash_map (ext infn) outfn) (lines file)


make_hash :: String -> ((String, String), (String, String))
make_hash str = let (chr : pos : fst_base : snd_base : xs) = words str
                in  ((chr, pos), (fst_base, snd_base))


untrim :: Map.Map (String,String) (String,String) -> String -> String -> String -> IO ()
untrim hash_map "vcf" outfn str@('#' : xs) = appendFile outfn $ str ++ "\n"
untrim hash_map "vcf" outfn str            = let (chr : pos : id : ref : alt :xs) = words str
                                                 (fst_base, snd_base) = case Map.lookup (chr, pos) hash_map of
                                                                           Just((a, b)) -> (a, b)
                                                                           Nothing      -> (ref, alt)
                                             in do
                                                 appendFile outfn $ (intercalate "\t" $ [chr, pos, id, fst_base, snd_base] ++ xs) ++ "\n"
untrim hash_map "bim" outfn str            = let (chr : id : x : pos : a0 : a1 : _) = words str
                                                 (fst_base, snd_base) = case Map.lookup (chr, pos) hash_map of
                                                                           Just((a, b)) -> (a, b)
                                                                           Nothing      -> (a0, a1)
                                             in do
                                                 appendFile outfn $ (intercalate "\t" $ [chr, id, x, pos, fst_base, snd_base]) ++ "\n"
